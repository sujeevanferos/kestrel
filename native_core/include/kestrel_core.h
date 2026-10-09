#ifndef KESTREL_CORE_H
#define KESTREL_CORE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(KESTREL_STATIC)
  #define KESTREL_API
#elif defined(_WIN32) || defined(__CYGWIN__)
  #if defined(KESTREL_EXPORTS)
    #define KESTREL_API __declspec(dllexport)
  #else
    #define KESTREL_API __declspec(dllimport)
  #endif
#else
  #if defined(__GNUC__) && __GNUC__ >= 4
    #define KESTREL_API __attribute__((visibility("default")))
  #else
    #define KESTREL_API
  #endif
#endif

/* Supported shape types */
typedef enum {
    KESTREL_SHAPE_HANDWRITING = 0,
    KESTREL_SHAPE_LINE        = 1,
    KESTREL_SHAPE_RECTANGLE   = 2,
    KESTREL_SHAPE_SQUARE      = 3,
    KESTREL_SHAPE_CIRCLE      = 4,
    KESTREL_SHAPE_ELLIPSE     = 5,
    KESTREL_SHAPE_TRIANGLE    = 6,
    KESTREL_SHAPE_ARROW       = 7,
    KESTREL_SHAPE_CLOUD       = 8
} KestrelShapeType;

/* 2D point with pressure, tilt, and timing */
typedef struct {
    double x;
    double y;
    double pressure;
    double tilt;
    double timestamp;
} KestrelPoint;

/* Bounding box */
typedef struct {
    double x;
    double y;
    double width;
    double height;
} KestrelBBox;

/* Classification output structure (C-compatible for Dart FFI) */
typedef struct {
    int32_t shape_type;        /* KestrelShapeType */
    double confidence;         /* 0.0 to 1.0 */
    KestrelBBox bbox;          /* Bounding box of original or fitted shape */
    
    /* Shape-specific parameters */
    double center_x;
    double center_y;
    double radius;             /* For circle / regular ngon */
    double radius_y;           /* For ellipse */
    double p1_x, p1_y;         /* Line / Arrow start */
    double p2_x, p2_y;         /* Line / Arrow end */
    int32_t arrow_head_at_p2;  /* 1 if head at p2, 0 if at p1 */

    /* Fitted vertices (e.g. rectangle corners, triangle, n-gon) */
    int32_t vertex_count;
    KestrelPoint vertices[32];
} KestrelClassificationResult;

/* ========================================================================= */
/* API FUNCTIONS                                                             */
/* ========================================================================= */

/**
 * Classifies an input stroke across all 8 supported shapes or handwriting.
 * Returns 1 on success, 0 on invalid input.
 */
KESTREL_API int kestrel_classify_stroke(
    const KestrelPoint* points,
    int count,
    KestrelClassificationResult* out_result
);

/**
 * Smooths and de-jitters handwriting using Catmull-Rom & B-spline interpolation.
 * Returns actual number of generated points in out_count.
 */
KESTREL_API int kestrel_smooth_stroke(
    const KestrelPoint* points,
    int count,
    double smooth_factor,
    KestrelPoint* out_points,
    int max_out_points,
    int* out_count
);

/**
 * Fits a straight line using Total Least Squares (PCA).
 */
KESTREL_API int kestrel_fit_line(
    const KestrelPoint* points,
    int count,
    KestrelClassificationResult* out_result
);

/**
 * Fits a circle using Kasa's algebraic least-squares method.
 */
KESTREL_API int kestrel_fit_circle(
    const KestrelPoint* points,
    int count,
    KestrelClassificationResult* out_result
);

/**
 * Generates vertex coordinates for a regular n-sided polygon.
 */
KESTREL_API int kestrel_generate_regular_ngon(
    double cx,
    double cy,
    double radius,
    int n,
    double angle_offset_rad,
    KestrelPoint* out_vertices,
    int* out_count
);

#ifdef __cplusplus
}
#endif

#endif /* KESTREL_CORE_H */
