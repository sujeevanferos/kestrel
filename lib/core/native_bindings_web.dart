import 'dart:math' as math;
import 'native_bindings_interface.dart';

class NativeCore {
  static final NativeCore instance = NativeCore._internal();
  NativeCore._internal();

  bool get isNativeAvailable => false;

  /// Classifies stroke points on web using pure Dart geometric algorithms
  ShapeResult classifyStroke(List<StrokePoint> points) {
    if (points.length < 3) {
      return const ShapeResult(
        type: KestrelShapeType.handwriting,
        confidence: 1.0,
        minX: 0,
        minY: 0,
        width: 0,
        height: 0,
      );
    }

    var minX = points.first.x, maxX = points.first.x;
    var minY = points.first.y, maxY = points.first.y;
    var totalLen = 0.0;

    for (var i = 1; i < points.length; ++i) {
      minX = math.min(minX, points[i].x);
      maxX = math.max(maxX, points[i].x);
      minY = math.min(minY, points[i].y);
      maxY = math.max(maxY, points[i].y);
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      totalLen += math.sqrt(dx * dx + dy * dy);
    }

    final w = maxX - minX, h = maxY - minY;
    final seDx = points.last.x - points.first.x;
    final seDy = points.last.y - points.first.y;
    final startEndDist = math.sqrt(seDx * seDx + seDy * seDy);
    final isClosed = startEndDist < math.max(45.0, math.sqrt(w * w + h * h) * 0.30);

    // 1. Line Check (Directness > 0.88)
    if (totalLen > 20 && (startEndDist / totalLen) >= 0.88) {
      return ShapeResult(
        type: KestrelShapeType.line,
        confidence: 0.94,
        minX: minX,
        minY: minY,
        width: w,
        height: h,
        p1X: points.first.x,
        p1Y: points.first.y,
        p2X: points.last.x,
        p2Y: points.last.y,
        vertices: [points.first, points.last],
      );
    }

    // 2. Closed Loop: Circle / Ellipse
    if (isClosed && w > 15 && h > 15) {
      final maxDim = math.max(w, h);
      final diffRatio = (maxDim > 0) ? (w - h).abs() / maxDim : 0.0;
      if (diffRatio <= 0.15) {
        final radius = (w + h) / 4.0;
        return ShapeResult(
          type: KestrelShapeType.circle,
          confidence: 0.92,
          minX: minX,
          minY: minY,
          width: w,
          height: h,
          centerX: minX + w / 2.0,
          centerY: minY + h / 2.0,
          radius: radius,
          radiusY: radius,
        );
      } else {
        return ShapeResult(
          type: KestrelShapeType.ellipse,
          confidence: 0.90,
          minX: minX,
          minY: minY,
          width: w,
          height: h,
          centerX: minX + w / 2.0,
          centerY: minY + h / 2.0,
          radius: w / 2.0,
          radiusY: h / 2.0,
        );
      }
    }

    // Fallback: Handwriting
    return ShapeResult(
      type: KestrelShapeType.handwriting,
      confidence: 1.0,
      minX: minX,
      minY: minY,
      width: w,
      height: h,
    );
  }

  /// Smooths raw points into Catmull-Rom spline curves
  List<StrokePoint> smoothStroke(List<StrokePoint> points, {double smoothFactor = 1.0}) {
    if (points.length < 3) return points;
    final result = <StrokePoint>[];

    for (var i = 0; i < points.length - 1; ++i) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      for (var t = 0.0; t < 1.0; t += 0.25) {
        final t2 = t * t;
        final t3 = t2 * t;
        final x = 0.5 * ((2.0 * p1.x) +
            (-p0.x + p2.x) * t +
            (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
            (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3);
        final y = 0.5 * ((2.0 * p1.y) +
            (-p0.y + p2.y) * t +
            (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
            (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3);
        result.add(StrokePoint(x: x, y: y, pressure: p1.pressure));
      }
    }
    result.add(points.last);
    return result;
  }

  /// Generates a regular n-sided polygon
  List<StrokePoint> generateRegularNgon(
    double cx,
    double cy,
    double radius,
    int n, {
    double angleOffset = -math.pi / 2,
  }) {
    final verts = <StrokePoint>[];
    for (var i = 0; i < n; ++i) {
      final theta = angleOffset + 2.0 * math.pi * i / n;
      verts.add(StrokePoint(
        x: cx + radius * math.cos(theta),
        y: cy + radius * math.sin(theta),
      ));
    }
    return verts;
  }
}
