#include "kestrel_core.h"
#include <iostream>
#include <vector>
#include <cmath>
#include <cassert>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

void test_line_fitting() {
    std::cout << "[TEST] Testing Line Fitting (PCA)..." << std::endl;
    std::vector<KestrelPoint> pts;
    for (int i = 0; i <= 50; ++i) {
        double x = i * 4.0;
        double y = 100.0 + ((i % 2 == 0) ? 0.5 : -0.5); // 0.5px subtle jitter
        pts.push_back({x, y, 1.0, 0.0, (double)i * 10});
    }

    KestrelClassificationResult res;
    int ok = kestrel_classify_stroke(pts.data(), (int)pts.size(), &res);
    assert(ok == 1);
    assert(res.shape_type == KESTREL_SHAPE_LINE);
    assert(res.confidence > 0.80);
    std::cout << "  -> PASSED: Line recognized, confidence: " << res.confidence
              << ", endpoints: (" << res.p1_x << ", " << res.p1_y << ") -> ("
              << res.p2_x << ", " << res.p2_y << ")" << std::endl;
}

void test_circle_fitting() {
    std::cout << "[TEST] Testing Circle Fitting (Kasa)..." << std::endl;
    std::vector<KestrelPoint> pts;
    double cx = 200.0, cy = 200.0, r = 60.0;
    int N = 64;
    for (int i = 0; i <= N; ++i) {
        double theta = 2.0 * M_PI * i / N;
        double noise = ((i % 3 == 0) ? 0.8 : -0.4);
        double x = cx + (r + noise) * std::cos(theta);
        double y = cy + (r + noise) * std::sin(theta);
        pts.push_back({x, y, 1.0, 0.0, (double)i * 10});
    }

    KestrelClassificationResult res;
    int ok = kestrel_classify_stroke(pts.data(), (int)pts.size(), &res);
    assert(ok == 1);
    assert(res.shape_type == KESTREL_SHAPE_CIRCLE);
    assert(std::abs(res.center_x - cx) < 3.0);
    assert(std::abs(res.center_y - cy) < 3.0);
    assert(std::abs(res.radius - r) < 3.0);
    std::cout << "  -> PASSED: Circle recognized, center: (" << res.center_x << ", " << res.center_y
              << "), radius: " << res.radius << std::endl;
}

void test_rectangle_fitting() {
    std::cout << "[TEST] Testing Rectangle/Square Fitting..." << std::endl;
    std::vector<KestrelPoint> pts;
    double x0 = 50.0, y0 = 50.0, w = 150.0, h = 80.0; // Unequal for rectangle

    // Draw 4 sides with dense points
    for (int i = 0; i < 20; ++i) pts.push_back({x0 + i * (w / 20.0), y0, 1.0, 0.0, 0});
    for (int i = 0; i < 20; ++i) pts.push_back({x0 + w, y0 + i * (h / 20.0), 1.0, 0.0, 0});
    for (int i = 0; i < 20; ++i) pts.push_back({x0 + w - i * (w / 20.0), y0 + h, 1.0, 0.0, 0});
    for (int i = 0; i < 20; ++i) pts.push_back({x0, y0 + h - i * (h / 20.0), 1.0, 0.0, 0});
    pts.push_back({x0, y0, 1.0, 0.0, 0}); // Close loop

    KestrelClassificationResult res;
    int ok = kestrel_classify_stroke(pts.data(), (int)pts.size(), &res);
    assert(ok == 1);
    assert(res.shape_type == KESTREL_SHAPE_RECTANGLE);
    assert(res.vertex_count == 4);
    std::cout << "  -> PASSED: Rectangle recognized with 4 corners." << std::endl;
}

void test_triangle_fitting() {
    std::cout << "[TEST] Testing Triangle Fitting..." << std::endl;
    std::vector<KestrelPoint> pts;
    KestrelPoint v[3] = {{100, 200, 1, 0, 0}, {200, 50, 1, 0, 0}, {300, 200, 1, 0, 0}};

    for (int side = 0; side < 3; ++side) {
        KestrelPoint p1 = v[side];
        KestrelPoint p2 = v[(side + 1) % 3];
        for (int i = 0; i < 20; ++i) {
            double t = (double)i / 20.0;
            pts.push_back({p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y), 1.0, 0.0, 0});
        }
    }
    pts.push_back(v[0]); // Close

    KestrelClassificationResult res;
    int ok = kestrel_classify_stroke(pts.data(), (int)pts.size(), &res);
    assert(ok == 1);
    assert(res.shape_type == KESTREL_SHAPE_TRIANGLE);
    assert(res.vertex_count == 3);
    std::cout << "  -> PASSED: Triangle recognized with 3 vertices." << std::endl;
}

void test_regular_ngon_generation() {
    std::cout << "[TEST] Testing Regular N-Gon Generation..." << std::endl;
    KestrelPoint verts[32];
    int count = 0;
    int ok = kestrel_generate_regular_ngon(100.0, 100.0, 50.0, 6, 0.0, verts, &count);
    assert(ok == 1);
    assert(count == 6);
    std::cout << "  -> PASSED: Hexagon generated with 6 vertices." << std::endl;
}

void test_stroke_smoothing() {
    std::cout << "[TEST] Testing Catmull-Rom Stroke Smoothing..." << std::endl;
    std::vector<KestrelPoint> pts = {
        {10, 10, 0.5, 0, 0},
        {30, 80, 0.7, 0, 10},
        {80, 40, 0.8, 0, 20},
        {120, 110, 0.6, 0, 30}
    };
    KestrelPoint out_pts[100];
    int out_count = 0;
    int ok = kestrel_smooth_stroke(pts.data(), (int)pts.size(), 1.0, out_pts, 100, &out_count);
    assert(ok == 1);
    assert(out_count > (int)pts.size());
    std::cout << "  -> PASSED: 4 raw points smoothed to " << out_count << " interpolated curve points." << std::endl;
}

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << "Running Kestrel Core Native Math Tests" << std::endl;
    std::cout << "========================================" << std::endl;

    test_line_fitting();
    test_circle_fitting();
    test_rectangle_fitting();
    test_triangle_fitting();
    test_regular_ngon_generation();
    test_stroke_smoothing();

    std::cout << "========================================" << std::endl;
    std::cout << "ALL NATIVE C++ TESTS PASSED SUCCESSFULLY!" << std::endl;
    std::cout << "========================================" << std::endl;
    return 0;
}
