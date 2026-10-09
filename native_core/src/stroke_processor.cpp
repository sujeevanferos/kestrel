#define KESTREL_EXPORTS
#include "kestrel_core.h"

#include <cmath>
#include <vector>
#include <algorithm>
#include <numeric>
#include <cfloat>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace {

// ==============================================================================
// THRESHOLD CONSTANTS
// ==============================================================================
constexpr int DOWNSAMPLE_MAX_POINTS = 200;
constexpr double LINE_MAX_RMSE_PX = 6.0;
constexpr double LINE_MAX_ERROR_PX = 14.0;
constexpr double LINE_MIN_DIRECTNESS = 0.85;

constexpr double ARROW_TAIL_RATIO = 0.20;
constexpr double ARROW_HEAD_LENGTH_PX = 16.0;
constexpr double ARROW_HEAD_ANGLE_DEG = 30.0;
constexpr double ARROW_FLARE_MIN_ANGLE_DEG = 20.0;
constexpr double ARROW_FLARE_MAX_ANGLE_DEG = 150.0;
constexpr double ARROW_SHAFT_MAX_RMSE_PX = 5.0;
constexpr double ARROW_MIN_DIRECTNESS = 0.45;

constexpr double CIRCLE_MAX_RELATIVE_ERROR = 0.18;
constexpr double CIRCLE_MAX_RMSE_PX = 10.0;
constexpr double SQUARE_TOLERANCE_RATIO = 0.10;

constexpr double CLOSED_LOOP_MAX_DIST_PX = 45.0;
constexpr double CLOSED_LOOP_RELATIVE_THRES = 0.30;

constexpr double CORNER_ANGLE_THRESHOLD_DEG = 30.0;
constexpr double MIN_CORNER_DISTANCE_PX = 12.0;
constexpr double RECTANGLE_ANGLE_TOLERANCE_DEG = 25.0;

constexpr int TRIANGLE_CORNER_COUNT = 3;

constexpr double CLOUD_MIN_BBOX_PX = 45.0;
constexpr double CLOUD_MIN_ARC_LENGTH_PX = 80.0;
constexpr double CLOUD_CURVATURE_VAR_THRESHOLD = 0.006;
constexpr int CLOUD_MIN_SIGN_CHANGES = 7;

constexpr double PRECHECK_MIN_ARC_LENGTH_PX = 20.0;
constexpr double PRECHECK_MIN_BBOX_DIAG_PX = 20.0;

inline double deg_to_rad(double deg) { return deg * M_PI / 180.0; }
inline double rad_to_deg(double rad) { return rad * 180.0 / M_PI; }
inline double distance(double x1, double y1, double x2, double y2) {
    return std::hypot(x2 - x1, y2 - y1);
}
inline double clamp(double val, double min_val, double max_val) {
    return std::max(min_val, std::min(val, max_val));
}

// ------------------------------------------------------------------------------
// Downsampling (Uniform arc-length resampling)
// ------------------------------------------------------------------------------
std::vector<KestrelPoint> downsample(const KestrelPoint* pts, int count, int max_points = DOWNSAMPLE_MAX_POINTS) {
    if (count <= max_points) {
        return std::vector<KestrelPoint>(pts, pts + count);
    }
    std::vector<double> cum_dist;
    cum_dist.reserve(count);
    cum_dist.push_back(0.0);
    double total_len = 0.0;
    for (int i = 1; i < count; ++i) {
        total_len += distance(pts[i - 1].x, pts[i - 1].y, pts[i].x, pts[i].y);
        cum_dist.push_back(total_len);
    }
    if (total_len < 1e-6) {
        return std::vector<KestrelPoint>(pts, pts + max_points);
    }

    std::vector<KestrelPoint> result;
    result.reserve(max_points);
    double step = total_len / (max_points - 1);
    int seg_idx = 0;

    for (int i = 0; i < max_points; ++i) {
        double target_d = i * step;
        while (seg_idx < count - 2 && cum_dist[seg_idx + 1] < target_d) {
            seg_idx++;
        }
        double seg_start_d = cum_dist[seg_idx];
        double seg_end_d = cum_dist[seg_idx + 1];
        double seg_len = seg_end_d - seg_start_d;
        double t = (seg_len > 1e-6) ? (target_d - seg_start_d) / seg_len : 0.0;
        t = clamp(t, 0.0, 1.0);

        KestrelPoint p;
        p.x = pts[seg_idx].x + t * (pts[seg_idx + 1].x - pts[seg_idx].x);
        p.y = pts[seg_idx].y + t * (pts[seg_idx + 1].y - pts[seg_idx].y);
        p.pressure = pts[seg_idx].pressure + t * (pts[seg_idx + 1].pressure - pts[seg_idx].pressure);
        p.tilt = pts[seg_idx].tilt;
        p.timestamp = pts[seg_idx].timestamp + t * (pts[seg_idx + 1].timestamp - pts[seg_idx].timestamp);
        result.push_back(p);
    }
    return result;
}

// ------------------------------------------------------------------------------
// Total Least Squares (PCA Line Fitting)
// ------------------------------------------------------------------------------
struct LineFitResult {
    bool is_valid = false;
    double p1_x = 0, p1_y = 0;
    double p2_x = 0, p2_y = 0;
    double dir_x = 0, dir_y = 0;
    double rmse = 1e9;
    double max_error = 1e9;
};

LineFitResult fit_line_internal(const KestrelPoint* pts, int count) {
    LineFitResult res;
    if (count < 2) return res;

    double mean_x = 0.0, mean_y = 0.0;
    for (int i = 0; i < count; ++i) {
        mean_x += pts[i].x;
        mean_y += pts[i].y;
    }
    mean_x /= count;
    mean_y /= count;

    double cxx = 0.0, cyy = 0.0, cxy = 0.0;
    for (int i = 0; i < count; ++i) {
        double dx = pts[i].x - mean_x;
        double dy = pts[i].y - mean_y;
        cxx += dx * dx;
        cyy += dy * dy;
        cxy += dx * dy;
    }

    // Principal component direction of 2x2 covariance matrix
    double trace = cxx + cyy;
    double det = cxx * cyy - cxy * cxy;
    double disc = std::sqrt(std::max(0.0, trace * trace - 4.0 * det));
    double lambda_max = (trace + disc) / 2.0;

    double vx = 1.0, vy = 0.0;
    if (std::abs(cxy) > 1e-9) {
        vx = lambda_max - cyy;
        vy = cxy;
    } else {
        if (cxx >= cyy) { vx = 1.0; vy = 0.0; }
        else { vx = 0.0; vy = 1.0; }
    }
    double v_norm = std::hypot(vx, vy);
    if (v_norm < 1e-9) return res;
    vx /= v_norm;
    vy /= v_norm;

    double nx = -vy, ny = vx; // Normal vector

    double sum_sq_err = 0.0;
    double max_err = 0.0;
    double min_proj = 1e9, max_proj = -1e9;

    for (int i = 0; i < count; ++i) {
        double dx = pts[i].x - mean_x;
        double dy = pts[i].y - mean_y;
        double perp_dist = std::abs(dx * nx + dy * ny);
        sum_sq_err += perp_dist * perp_dist;
        max_err = std::max(max_err, perp_dist);

        double proj = dx * vx + dy * vy;
        min_proj = std::min(min_proj, proj);
        max_proj = std::max(max_proj, proj);
    }

    res.is_valid = true;
    res.rmse = std::sqrt(sum_sq_err / count);
    res.max_error = max_err;
    res.dir_x = vx;
    res.dir_y = vy;
    res.p1_x = mean_x + min_proj * vx;
    res.p1_y = mean_y + min_proj * vy;
    res.p2_x = mean_x + max_proj * vx;
    res.p2_y = mean_y + max_proj * vy;
    return res;
}

// ------------------------------------------------------------------------------
// Kasa Algebraic Circle Fitting
// ------------------------------------------------------------------------------
struct CircleFitResult {
    bool is_valid = false;
    double cx = 0, cy = 0;
    double radius = 0;
    double rmse = 1e9;
    double relative_error = 1e9;
};

CircleFitResult fit_circle_kasa_internal(const KestrelPoint* pts, int count) {
    CircleFitResult res;
    if (count < 4) return res;

    // Normal equations for A * [D, E, F]^T = B, where A = [x, y, 1], B = -(x^2 + y^2)
    double s_x = 0, s_y = 0;
    double s_xx = 0, s_yy = 0, s_xy = 0;
    double s_x3 = 0, s_y3 = 0, s_xy2 = 0, s_x2y = 0;

    for (int i = 0; i < count; ++i) {
        double x = pts[i].x, y = pts[i].y;
        double x2 = x * x, y2 = y * y;
        s_x += x; s_y += y;
        s_xx += x2; s_yy += y2; s_xy += x * y;
        s_x3 += x * x2; s_y3 += y * y2;
        s_xy2 += x * y2; s_x2y += x2 * y;
    }

    double m00 = s_xx, m01 = s_xy, m02 = s_x;
    double m10 = s_xy, m11 = s_yy, m12 = s_y;
    double m20 = s_x,  m21 = s_y,  m22 = (double)count;

    double b0 = -(s_x3 + s_xy2);
    double b1 = -(s_x2y + s_y3);
    double b2 = -(s_xx + s_yy);

    // 3x3 Determinant
    double det = m00 * (m11 * m22 - m12 * m21) -
                 m01 * (m10 * m22 - m12 * m20) +
                 m02 * (m10 * m21 - m11 * m20);

    if (std::abs(det) < 1e-9) return res;

    double detD = b0  * (m11 * m22 - m12 * m21) -
                  m01 * (b1  * m22 - m12 * b2)  +
                  m02 * (b1  * m21 - m11 * b2);

    double detE = m00 * (b1  * m22 - m12 * b2)  -
                  b0  * (m10 * m22 - m12 * m20) +
                  m02 * (m10 * b2  - b1  * m20);

    double detF = m00 * (m11 * b2  - b1  * m21) -
                  m01 * (m10 * b2  - b1  * m20) +
                  b0  * (m10 * m21 - m11 * m20);

    double D = detD / det;
    double E = detE / det;
    double F = detF / det;

    double cx = -D / 2.0;
    double cy = -E / 2.0;
    double val = (D * D + E * E) / 4.0 - F;
    if (val <= 0.0) return res;

    double radius = std::sqrt(val);

    double sum_sq_err = 0.0;
    for (int i = 0; i < count; ++i) {
        double d = distance(pts[i].x, pts[i].y, cx, cy);
        double err = std::abs(d - radius);
        sum_sq_err += err * err;
    }
    double rmse = std::sqrt(sum_sq_err / count);

    res.is_valid = true;
    res.cx = cx;
    res.cy = cy;
    res.radius = radius;
    res.rmse = rmse;
    res.relative_error = (radius > 0) ? (rmse / radius) : 1e9;
    return res;
}

// ------------------------------------------------------------------------------
// Corner Detection via Tangent Angle Changes
// ------------------------------------------------------------------------------
std::vector<int> detect_corners_internal(const KestrelPoint* pts, int count,
                                         double min_angle_deg = CORNER_ANGLE_THRESHOLD_DEG,
                                         double min_dist_px = MIN_CORNER_DISTANCE_PX) {
    std::vector<int> filtered;
    if (count < 8) return filtered;

    int window = std::max(2, std::min(8, count / 15));
    std::vector<double> angles(count, 0.0);
    double min_angle_rad = deg_to_rad(min_angle_deg);

    for (int i = window; i < count - window; ++i) {
        double vin_x = pts[i].x - pts[i - window].x;
        double vin_y = pts[i].y - pts[i - window].y;
        double vout_x = pts[i + window].x - pts[i].x;
        double vout_y = pts[i + window].y - pts[i].y;

        double norm_in = std::hypot(vin_x, vin_y);
        double norm_out = std::hypot(vout_x, vout_y);
        if (norm_in > 1e-4 && norm_out > 1e-4) {
            double dot = (vin_x * vout_x + vin_y * vout_y) / (norm_in * norm_out);
            dot = clamp(dot, -1.0, 1.0);
            angles[i] = std::acos(dot);
        }
    }

    std::vector<std::pair<int, double>> peaks;
    for (int i = window + 1; i < count - window - 1; ++i) {
        if (angles[i] >= min_angle_rad && angles[i] >= angles[i - 1] && angles[i] >= angles[i + 1]) {
            peaks.push_back({i, angles[i]});
        }
    }

    for (const auto& p : peaks) {
        int idx = p.first;
        if (filtered.empty()) {
            filtered.push_back(idx);
        } else {
            int prev_idx = filtered.back();
            double d = distance(pts[idx].x, pts[idx].y, pts[prev_idx].x, pts[prev_idx].y);
            if (d >= min_dist_px) {
                filtered.push_back(idx);
            }
        }
    }
    return filtered;
}

// ------------------------------------------------------------------------------
// Arrow Fitting
// ------------------------------------------------------------------------------
struct ArrowFitResult {
    bool is_valid = false;
    double p1_x = 0, p1_y = 0;
    double p2_x = 0, p2_y = 0;
    int head_at_p2 = 1;
};

ArrowFitResult fit_arrow_internal(const KestrelPoint* pts, int count) {
    ArrowFitResult res;
    if (count < 10) return res;

    double start_end_dist = distance(pts[0].x, pts[0].y, pts[count - 1].x, pts[count - 1].y);
    double total_len = 0.0;
    for (int i = 1; i < count; ++i) {
        total_len += distance(pts[i - 1].x, pts[i - 1].y, pts[i].x, pts[i].y);
    }
    if (total_len < 1e-6) return res;

    double directness = start_end_dist / total_len;
    if (directness < ARROW_MIN_DIRECTNESS) return res;

    int tail_count = std::max(4, (int)(count * ARROW_TAIL_RATIO));

    // Try flare at tail end (p2)
    int shaft_len_tail = count - tail_count;
    LineFitResult shaft_tail = fit_line_internal(pts, shaft_len_tail);
    if (shaft_tail.is_valid && shaft_tail.rmse <= ARROW_SHAFT_MAX_RMSE_PX) {
        double shaft_dx = shaft_tail.p2_x - shaft_tail.p1_x;
        double shaft_dy = shaft_tail.p2_y - shaft_tail.p1_y;
        double s_len = std::hypot(shaft_dx, shaft_dy);
        if (s_len >= 15.0) {
            double unit_sx = shaft_dx / s_len, unit_sy = shaft_dy / s_len;
            bool has_flare = false;
            for (int i = shaft_len_tail; i < count - 1; ++i) {
                double vx = pts[i + 1].x - pts[i].x;
                double vy = pts[i + 1].y - pts[i].y;
                double v_len = std::hypot(vx, vy);
                if (v_len < 1e-3) continue;
                double dot = clamp((vx * unit_sx + vy * unit_sy) / v_len, -1.0, 1.0);
                double ang_deg = rad_to_deg(std::acos(dot));
                if (ang_deg >= ARROW_FLARE_MIN_ANGLE_DEG && ang_deg <= ARROW_FLARE_MAX_ANGLE_DEG) {
                    has_flare = true;
                    break;
                }
            }
            if (has_flare) {
                res.is_valid = true;
                res.p1_x = shaft_tail.p1_x; res.p1_y = shaft_tail.p1_y;
                res.p2_x = shaft_tail.p2_x; res.p2_y = shaft_tail.p2_y;
                res.head_at_p2 = 1;
                return res;
            }
        }
    }

    // Try flare at start end (p1)
    const KestrelPoint* shaft_start_pts = pts + tail_count;
    int shaft_len_head = count - tail_count;
    LineFitResult shaft_head = fit_line_internal(shaft_start_pts, shaft_len_head);
    if (shaft_head.is_valid && shaft_head.rmse <= ARROW_SHAFT_MAX_RMSE_PX) {
        double shaft_dx = shaft_head.p2_x - shaft_head.p1_x;
        double shaft_dy = shaft_head.p2_y - shaft_head.p1_y;
        double s_len = std::hypot(shaft_dx, shaft_dy);
        if (s_len >= 15.0) {
            double unit_sx = -shaft_dx / s_len, unit_sy = -shaft_dy / s_len;
            bool has_flare = false;
            for (int i = 0; i < tail_count - 1; ++i) {
                double vx = pts[i + 1].x - pts[i].x;
                double vy = pts[i + 1].y - pts[i].y;
                double v_len = std::hypot(vx, vy);
                if (v_len < 1e-3) continue;
                double dot = clamp((vx * unit_sx + vy * unit_sy) / v_len, -1.0, 1.0);
                double ang_deg = rad_to_deg(std::acos(dot));
                if (ang_deg >= ARROW_FLARE_MIN_ANGLE_DEG && ang_deg <= ARROW_FLARE_MAX_ANGLE_DEG) {
                    has_flare = true;
                    break;
                }
            }
            if (has_flare) {
                res.is_valid = true;
                res.p1_x = shaft_head.p2_x; res.p1_y = shaft_head.p2_y;
                res.p2_x = shaft_head.p1_x; res.p2_y = shaft_head.p1_y;
                res.head_at_p2 = 0;
                return res;
            }
        }
    }

    return res;
}

// ------------------------------------------------------------------------------
// Rectangle & Square Fitting
// ------------------------------------------------------------------------------
struct RectFitResult {
    bool is_valid = false;
    bool is_square = false;
    double min_x = 0, min_y = 0, w = 0, h = 0;
    KestrelPoint corners[4];
};

RectFitResult fit_rectangle_internal(const KestrelPoint* pts, int count,
                                     double start_end_dist, double bbox_diag,
                                     double min_x, double min_y, double w, double h) {
    RectFitResult res;
    if (w < 5.0 || h < 5.0) return res;

    bool is_closed = start_end_dist < std::max(CLOSED_LOOP_MAX_DIST_PX, bbox_diag * CLOSED_LOOP_RELATIVE_THRES);
    std::vector<int> corners = detect_corners_internal(pts, count);

    if (corners.size() == 3 && is_closed) {
        corners.insert(corners.begin(), 0);
    }
    if (corners.size() == 5 && is_closed) {
        if (distance(pts[corners[0]].x, pts[corners[0]].y, pts[corners[4]].x, pts[corners[4]].y) < 25.0) {
            corners.pop_back();
        }
    }

    if (corners.size() != 4) return res;

    KestrelPoint c_pts[4];
    for (int i = 0; i < 4; ++i) c_pts[i] = pts[corners[i]];

    // Check interior corner angles
    for (int i = 0; i < 4; ++i) {
        int prev = (i + 3) % 4;
        int next = (i + 1) % 4;
        double vin_x = c_pts[i].x - c_pts[prev].x;
        double vin_y = c_pts[i].y - c_pts[prev].y;
        double vout_x = c_pts[next].x - c_pts[i].x;
        double vout_y = c_pts[next].y - c_pts[i].y;
        double nin = std::hypot(vin_x, vin_y);
        double nout = std::hypot(vout_x, vout_y);
        if (nin < 1e-4 || nout < 1e-4) return res;
        double dot = clamp(-(vin_x * vout_x + vin_y * vout_y) / (nin * nout), -1.0, 1.0);
        double ang_deg = rad_to_deg(std::acos(dot));
        if (std::abs(ang_deg - 90.0) >= RECTANGLE_ANGLE_TOLERANCE_DEG) {
            return res;
        }
    }

    res.is_valid = true;
    double max_dim = std::max(w, h);
    double diff_ratio = (max_dim > 0) ? std::abs(w - h) / max_dim : 0.0;
    if (diff_ratio <= SQUARE_TOLERANCE_RATIO) {
        res.is_square = true;
        double side = (w + h) / 2.0;
        double cx = min_x + w / 2.0;
        double cy = min_y + h / 2.0;
        res.min_x = cx - side / 2.0;
        res.min_y = cy - side / 2.0;
        res.w = side;
        res.h = side;
    } else {
        res.is_square = false;
        res.min_x = min_x;
        res.min_y = min_y;
        res.w = w;
        res.h = h;
    }

    res.corners[0] = {res.min_x, res.min_y, 0, 0, 0};
    res.corners[1] = {res.min_x + res.w, res.min_y, 0, 0, 0};
    res.corners[2] = {res.min_x + res.w, res.min_y + res.h, 0, 0, 0};
    res.corners[3] = {res.min_x, res.min_y + res.h, 0, 0, 0};
    return res;
}

// ------------------------------------------------------------------------------
// Triangle Fitting
// ------------------------------------------------------------------------------
struct TriFitResult {
    bool is_valid = false;
    KestrelPoint corners[3];
};

TriFitResult fit_triangle_internal(const KestrelPoint* pts, int count,
                                   double start_end_dist, double bbox_diag,
                                   double min_x, double min_y, double w, double h) {
    TriFitResult res;
    if (w < 5.0 || h < 5.0) return res;

    bool is_closed = start_end_dist < std::max(CLOSED_LOOP_MAX_DIST_PX, bbox_diag * CLOSED_LOOP_RELATIVE_THRES);
    if (!is_closed) return res;

    std::vector<int> corners = detect_corners_internal(pts, count);
    if (corners.size() == 2) {
        corners.insert(corners.begin(), 0);
    }
    if (corners.size() == 4) {
        if (distance(pts[corners[0]].x, pts[corners[0]].y, pts[corners[3]].x, pts[corners[3]].y) < std::max(25.0, bbox_diag * 0.15)) {
            corners.pop_back();
        }
    }
    if (corners.size() != TRIANGLE_CORNER_COUNT) return res;

    KestrelPoint c_pts[3];
    for (int i = 0; i < 3; ++i) c_pts[i] = pts[corners[i]];

    double cx = (c_pts[0].x + c_pts[1].x + c_pts[2].x) / 3.0;
    double cy = (c_pts[0].y + c_pts[1].y + c_pts[2].y) / 3.0;

    // Sort around centroid
    std::sort(c_pts, c_pts + 3, [cx, cy](const KestrelPoint& a, const KestrelPoint& b) {
        return std::atan2(a.y - cy, a.x - cx) < std::atan2(b.y - cy, b.x - cx);
    });

    for (int i = 0; i < 3; ++i) {
        int prev = (i + 2) % 3;
        int next = (i + 1) % 3;
        double vin_x = c_pts[i].x - c_pts[prev].x;
        double vin_y = c_pts[i].y - c_pts[prev].y;
        double vout_x = c_pts[next].x - c_pts[i].x;
        double vout_y = c_pts[next].y - c_pts[i].y;
        double nin = std::hypot(vin_x, vin_y);
        double nout = std::hypot(vout_x, vout_y);
        if (nin < 1e-4 || nout < 1e-4) return res;
        double dot = clamp(-(vin_x * vout_x + vin_y * vout_y) / (nin * nout), -1.0, 1.0);
        double ang_deg = rad_to_deg(std::acos(dot));
        if (ang_deg < 20.0 || ang_deg > 140.0) {
            return res;
        }
    }

    res.is_valid = true;
    res.corners[0] = c_pts[0];
    res.corners[1] = c_pts[1];
    res.corners[2] = c_pts[2];
    return res;
}

// ------------------------------------------------------------------------------
// Cloud Fitting
// ------------------------------------------------------------------------------
bool fit_cloud_internal(const KestrelPoint* pts, int count,
                        double start_end_dist, double bbox_diag,
                        double w, double h, double total_length) {
    if (count < 16) return false;
    bool is_closed = start_end_dist < std::max(CLOSED_LOOP_MAX_DIST_PX, bbox_diag * CLOSED_LOOP_RELATIVE_THRES);
    if (!is_closed) return false;
    if (w < CLOUD_MIN_BBOX_PX || h < CLOUD_MIN_BBOX_PX) return false;
    if (total_length < CLOUD_MIN_ARC_LENGTH_PX) return false;

    auto corners = detect_corners_internal(pts, count);
    if (corners.size() >= 3 && corners.size() <= 5) return false; // Likely polygon/box

    auto eval_pts = downsample(pts, count, 100);
    int eval_n = (int)eval_pts.size();
    if (eval_n < 10) return false;

    std::vector<double> angle_changes;
    angle_changes.reserve(eval_n);

    for (int i = 1; i < eval_n - 1; ++i) {
        double v1x = eval_pts[i].x - eval_pts[i - 1].x;
        double v1y = eval_pts[i].y - eval_pts[i - 1].y;
        double v2x = eval_pts[i + 1].x - eval_pts[i].x;
        double v2y = eval_pts[i + 1].y - eval_pts[i].y;
        double n1 = std::hypot(v1x, v1y), n2 = std::hypot(v2x, v2y);
        if (n1 > 1e-4 && n2 > 1e-4) {
            double cross = (v1x * v2y - v1y * v2x) / (n1 * n2);
            angle_changes.push_back(std::asin(clamp(cross, -1.0, 1.0)));
        }
    }
    if (angle_changes.size() < 10) return false;

    double mean_ac = 0.0;
    for (double ac : angle_changes) mean_ac += ac;
    mean_ac /= angle_changes.size();

    double var_ac = 0.0;
    for (double ac : angle_changes) var_ac += (ac - mean_ac) * (ac - mean_ac);
    var_ac /= angle_changes.size();

    int sign_changes = 0;
    int prev_sign = 0;
    for (double ac : angle_changes) {
        int s = (ac > 1e-4) ? 1 : ((ac < -1e-4) ? -1 : 0);
        if (s != 0) {
            if (prev_sign != 0 && s != prev_sign) sign_changes++;
            prev_sign = s;
        }
    }

    return (var_ac >= CLOUD_CURVATURE_VAR_THRESHOLD && sign_changes >= CLOUD_MIN_SIGN_CHANGES);
}

} // anonymous namespace

// ==============================================================================
// EXPORTED C-ABI FUNCTIONS
// ==============================================================================

int kestrel_generate_regular_ngon(
    double cx, double cy, double radius, int n,
    double angle_offset_rad, KestrelPoint* out_vertices, int* out_count) {
    if (!out_vertices || !out_count || n < 3) return 0;
    int actual_n = std::min(n, 32);
    *out_count = actual_n;
    for (int i = 0; i < actual_n; ++i) {
        double theta = angle_offset_rad + 2.0 * M_PI * i / actual_n;
        out_vertices[i].x = cx + radius * std::cos(theta);
        out_vertices[i].y = cy + radius * std::sin(theta);
        out_vertices[i].pressure = 1.0;
        out_vertices[i].tilt = 0.0;
        out_vertices[i].timestamp = 0.0;
    }
    return 1;
}

int kestrel_fit_line(const KestrelPoint* points, int count, KestrelClassificationResult* out_result) {
    if (!points || count < 2 || !out_result) return 0;
    LineFitResult res = fit_line_internal(points, count);
    if (!res.is_valid) return 0;

    out_result->shape_type = KESTREL_SHAPE_LINE;
    out_result->confidence = std::max(0.5, 1.0 - (res.rmse / LINE_MAX_RMSE_PX) * 0.5);
    out_result->p1_x = res.p1_x; out_result->p1_y = res.p1_y;
    out_result->p2_x = res.p2_x; out_result->p2_y = res.p2_y;
    out_result->vertex_count = 2;
    out_result->vertices[0] = {res.p1_x, res.p1_y, 1.0, 0.0, 0.0};
    out_result->vertices[1] = {res.p2_x, res.p2_y, 1.0, 0.0, 0.0};
    return 1;
}

int kestrel_fit_circle(const KestrelPoint* points, int count, KestrelClassificationResult* out_result) {
    if (!points || count < 4 || !out_result) return 0;
    CircleFitResult res = fit_circle_kasa_internal(points, count);
    if (!res.is_valid) return 0;

    out_result->shape_type = KESTREL_SHAPE_CIRCLE;
    out_result->confidence = 0.94;
    out_result->center_x = res.cx;
    out_result->center_y = res.cy;
    out_result->radius = res.radius;
    out_result->radius_y = res.radius;
    out_result->vertex_count = 0;
    return 1;
}

int kestrel_classify_stroke(const KestrelPoint* points, int count, KestrelClassificationResult* out_result) {
    if (!points || count < 2 || !out_result) return 0;

    // Compute basic geometry
    double min_x = points[0].x, max_x = points[0].x;
    double min_y = points[0].y, max_y = points[0].y;
    double total_length = 0.0;
    for (int i = 1; i < count; ++i) {
        min_x = std::min(min_x, points[i].x);
        max_x = std::max(max_x, points[i].x);
        min_y = std::min(min_y, points[i].y);
        max_y = std::max(max_y, points[i].y);
        total_length += distance(points[i - 1].x, points[i - 1].y, points[i].x, points[i].y);
    }
    double w = max_x - min_x, h = max_y - min_y;
    double bbox_diag = std::hypot(w, h);
    double start_end_dist = distance(points[0].x, points[0].y, points[count - 1].x, points[count - 1].y);

    out_result->bbox.x = min_x;
    out_result->bbox.y = min_y;
    out_result->bbox.width = w;
    out_result->bbox.height = h;

    // Precheck filter (micro strokes are always handwriting)
    if (count < 4 || total_length < PRECHECK_MIN_ARC_LENGTH_PX || bbox_diag < PRECHECK_MIN_BBOX_DIAG_PX) {
        out_result->shape_type = KESTREL_SHAPE_HANDWRITING;
        out_result->confidence = 1.0;
        out_result->vertex_count = 0;
        return 1;
    }

    auto eval_pts = downsample(points, count, DOWNSAMPLE_MAX_POINTS);
    int eval_n = (int)eval_pts.size();
    bool is_closed = start_end_dist < std::max(CLOSED_LOOP_MAX_DIST_PX, bbox_diag * CLOSED_LOOP_RELATIVE_THRES);

    // 1. Circle / Ellipse (Closed smooth loops)
    CircleFitResult circle_fit = fit_circle_kasa_internal(eval_pts.data(), eval_n);
    if (circle_fit.is_valid &&
        circle_fit.relative_error < CIRCLE_MAX_RELATIVE_ERROR &&
        circle_fit.rmse < CIRCLE_MAX_RMSE_PX &&
        is_closed) {

        double max_dim = std::max(w, h);
        double diff_ratio = (max_dim > 0) ? std::abs(w - h) / max_dim : 0.0;
        if (diff_ratio <= SQUARE_TOLERANCE_RATIO) {
            out_result->shape_type = KESTREL_SHAPE_CIRCLE;
            out_result->confidence = 0.94;
            out_result->center_x = circle_fit.cx;
            out_result->center_y = circle_fit.cy;
            out_result->radius = circle_fit.radius;
            out_result->radius_y = circle_fit.radius;
            out_result->vertex_count = 0;
            return 1;
        } else {
            out_result->shape_type = KESTREL_SHAPE_ELLIPSE;
            out_result->confidence = 0.91;
            out_result->center_x = min_x + w / 2.0;
            out_result->center_y = min_y + h / 2.0;
            out_result->radius = w / 2.0;
            out_result->radius_y = h / 2.0;
            out_result->vertex_count = 0;
            return 1;
        }
    }

    // 2. Rectangle / Square (4 corners near 90 deg)
    RectFitResult rect_fit = fit_rectangle_internal(eval_pts.data(), eval_n,
                                                    start_end_dist, bbox_diag,
                                                    min_x, min_y, w, h);
    if (rect_fit.is_valid) {
        out_result->shape_type = rect_fit.is_square ? KESTREL_SHAPE_SQUARE : KESTREL_SHAPE_RECTANGLE;
        out_result->confidence = 0.92;
        out_result->bbox.x = rect_fit.min_x;
        out_result->bbox.y = rect_fit.min_y;
        out_result->bbox.width = rect_fit.w;
        out_result->bbox.height = rect_fit.h;
        out_result->vertex_count = 4;
        for (int i = 0; i < 4; ++i) out_result->vertices[i] = rect_fit.corners[i];
        return 1;
    }

    // 2b. Triangle (3 corners, closed)
    if (is_closed) {
        TriFitResult tri_fit = fit_triangle_internal(eval_pts.data(), eval_n,
                                                     start_end_dist, bbox_diag,
                                                     min_x, min_y, w, h);
        if (tri_fit.is_valid) {
            out_result->shape_type = KESTREL_SHAPE_TRIANGLE;
            out_result->confidence = 0.91;
            out_result->vertex_count = 3;
            for (int i = 0; i < 3; ++i) out_result->vertices[i] = tri_fit.corners[i];
            return 1;
        }
    }

    // 3. Cloud (Organic curvature oscillations)
    if (fit_cloud_internal(eval_pts.data(), eval_n, start_end_dist, bbox_diag, w, h, total_length)) {
        out_result->shape_type = KESTREL_SHAPE_CLOUD;
        out_result->confidence = 0.90;
        out_result->vertex_count = 0;
        return 1;
    }

    // 4. Arrow (Line shaft + endpoint flare)
    ArrowFitResult arrow_fit = fit_arrow_internal(eval_pts.data(), eval_n);
    if (arrow_fit.is_valid) {
        out_result->shape_type = KESTREL_SHAPE_ARROW;
        out_result->confidence = 0.95;
        out_result->p1_x = arrow_fit.p1_x; out_result->p1_y = arrow_fit.p1_y;
        out_result->p2_x = arrow_fit.p2_x; out_result->p2_y = arrow_fit.p2_y;
        out_result->arrow_head_at_p2 = arrow_fit.head_at_p2;
        out_result->vertex_count = 2;
        out_result->vertices[0] = {arrow_fit.p1_x, arrow_fit.p1_y, 1.0, 0.0, 0.0};
        out_result->vertices[1] = {arrow_fit.p2_x, arrow_fit.p2_y, 1.0, 0.0, 0.0};
        return 1;
    }

    // 5. Straight Line (PCA Total Least Squares)
    LineFitResult line_fit = fit_line_internal(eval_pts.data(), eval_n);
    double directness = (total_length > 0) ? (start_end_dist / total_length) : 0.0;
    if (line_fit.is_valid &&
        line_fit.rmse <= LINE_MAX_RMSE_PX &&
        line_fit.max_error <= LINE_MAX_ERROR_PX &&
        directness >= LINE_MIN_DIRECTNESS) {
        out_result->shape_type = KESTREL_SHAPE_LINE;
        out_result->confidence = 0.95;
        out_result->p1_x = line_fit.p1_x; out_result->p1_y = line_fit.p1_y;
        out_result->p2_x = line_fit.p2_x; out_result->p2_y = line_fit.p2_y;
        out_result->vertex_count = 2;
        out_result->vertices[0] = {line_fit.p1_x, line_fit.p1_y, 1.0, 0.0, 0.0};
        out_result->vertices[1] = {line_fit.p2_x, line_fit.p2_y, 1.0, 0.0, 0.0};
        return 1;
    }

    // Fallback: Handwriting
    out_result->shape_type = KESTREL_SHAPE_HANDWRITING;
    out_result->confidence = 1.0;
    out_result->vertex_count = 0;
    return 1;
}

int kestrel_smooth_stroke(
    const KestrelPoint* points, int count, double smooth_factor,
    KestrelPoint* out_points, int max_out_points, int* out_count) {
    if (!points || count < 2 || !out_points || !out_count || max_out_points < 2) {
        return 0;
    }
    if (count == 2 || max_out_points < 4) {
        int n = std::min(count, max_out_points);
        for (int i = 0; i < n; ++i) out_points[i] = points[i];
        *out_count = n;
        return 1;
    }

    // Centripetal Catmull-Rom Spline Interpolation with uniform arc-length sampling
    std::vector<KestrelPoint> pts;
    pts.reserve(count + 2);
    // Duplicate start & end for boundary tangent estimation
    pts.push_back(points[0]);
    for (int i = 0; i < count; ++i) pts.push_back(points[i]);
    pts.push_back(points[count - 1]);

    int generated = 0;
    int segments = count - 1;
    int samples_per_seg = std::max(2, max_out_points / segments);

    for (int i = 1; i <= segments; ++i) {
        const KestrelPoint& p0 = pts[i - 1];
        const KestrelPoint& p1 = pts[i];
        const KestrelPoint& p2 = pts[i + 1];
        const KestrelPoint& p3 = pts[i + 2];

        for (int s = 0; s < samples_per_seg; ++s) {
            if (generated >= max_out_points) break;
            double t = (double)s / samples_per_seg;
            double t2 = t * t;
            double t3 = t2 * t;

            // Catmull-Rom basis matrix (tension = 0.5)
            double x = 0.5 * ((2.0 * p1.x) +
                             (-p0.x + p2.x) * t +
                             (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
                             (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3);

            double y = 0.5 * ((2.0 * p1.y) +
                             (-p0.y + p2.y) * t +
                             (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
                             (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3);

            double pressure = p1.pressure + t * (p2.pressure - p1.pressure);
            double timestamp = p1.timestamp + t * (p2.timestamp - p1.timestamp);

            out_points[generated++] = {x, y, pressure, p1.tilt, timestamp};
        }
    }

    if (generated < max_out_points) {
        out_points[generated++] = points[count - 1];
    }
    *out_count = generated;
    return 1;
}
