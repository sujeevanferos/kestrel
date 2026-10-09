import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';

// Shape types matching C enum
enum KestrelShapeType {
  handwriting,
  line,
  rectangle,
  square,
  circle,
  ellipse,
  triangle,
  arrow,
  cloud,
}

// -----------------------------------------------------------------------------
// FFI C-STRUCTS
// -----------------------------------------------------------------------------

final class CKestrelPoint extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double pressure;

  @Double()
  external double tilt;

  @Double()
  external double timestamp;
}

final class CKestrelBBox extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double width;

  @Double()
  external double height;
}

final class CKestrelClassificationResult extends Struct {
  @Int32()
  external int shapeType;

  @Double()
  external double confidence;

  external CKestrelBBox bbox;

  @Double()
  external double centerX;

  @Double()
  external double centerY;

  @Double()
  external double radius;

  @Double()
  external double radiusY;

  @Double()
  external double p1X;

  @Double()
  external double p1Y;

  @Double()
  external double p2X;

  @Double()
  external double p2Y;

  @Int32()
  external int arrowHeadAtP2;

  @Int32()
  external int vertexCount;

  @Array(32)
  external Array<CKestrelPoint> vertices;
}

// -----------------------------------------------------------------------------
// FFI FUNCTION SIGNATURES
// -----------------------------------------------------------------------------

typedef CKestrelClassifyStroke = Int32 Function(
  Pointer<CKestrelPoint> points,
  Int32 count,
  Pointer<CKestrelClassificationResult> outResult,
);
typedef DartKestrelClassifyStroke = int Function(
  Pointer<CKestrelPoint> points,
  int count,
  Pointer<CKestrelClassificationResult> outResult,
);

typedef CKestrelSmoothStroke = Int32 Function(
  Pointer<CKestrelPoint> points,
  Int32 count,
  Double smoothFactor,
  Pointer<CKestrelPoint> outPoints,
  Int32 maxOutPoints,
  Pointer<Int32> outCount,
);
typedef DartKestrelSmoothStroke = int Function(
  Pointer<CKestrelPoint> points,
  int count,
  double smoothFactor,
  Pointer<CKestrelPoint> outPoints,
  int maxOutPoints,
  Pointer<Int32> outCount,
);

typedef CKestrelGenerateNgon = Int32 Function(
  Double cx,
  Double cy,
  Double radius,
  Int32 n,
  Double angleOffset,
  Pointer<CKestrelPoint> outVertices,
  Pointer<Int32> outCount,
);
typedef DartKestrelGenerateNgon = int Function(
  double cx,
  double cy,
  double radius,
  int n,
  double angleOffset,
  Pointer<CKestrelPoint> outVertices,
  Pointer<Int32> outCount,
);

// -----------------------------------------------------------------------------
// HIGH-LEVEL DART DATA MODELS
// -----------------------------------------------------------------------------

class StrokePoint {
  final double x;
  final double y;
  final double pressure;
  final double tilt;
  final double timestamp;

  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.timestamp = 0.0,
  });
}

class ShapeResult {
  final KestrelShapeType type;
  final double confidence;
  final double minX;
  final double minY;
  final double width;
  final double height;
  final double centerX;
  final double centerY;
  final double radius;
  final double radiusY;
  final double p1X;
  final double p1Y;
  final double p2X;
  final double p2Y;
  final bool arrowHeadAtP2;
  final List<StrokePoint> vertices;

  const ShapeResult({
    required this.type,
    required this.confidence,
    required this.minX,
    required this.minY,
    required this.width,
    required this.height,
    this.centerX = 0,
    this.centerY = 0,
    this.radius = 0,
    this.radiusY = 0,
    this.p1X = 0,
    this.p1Y = 0,
    this.p2X = 0,
    this.p2Y = 0,
    this.arrowHeadAtP2 = true,
    this.vertices = const [],
  });
}

// -----------------------------------------------------------------------------
// NATIVE CORE SINGLETON & FALLBACK
// -----------------------------------------------------------------------------

class NativeCore {
  static final NativeCore instance = NativeCore._internal();
  NativeCore._internal() {
    _initLib();
  }

  DynamicLibrary? _dylib;
  DartKestrelClassifyStroke? _classifyFn;
  DartKestrelSmoothStroke? _smoothFn;
  DartKestrelGenerateNgon? _ngonFn;
  bool _isNativeAvailable = false;

  bool get isNativeAvailable => _isNativeAvailable;

  void _initLib() {
    try {
      if (Platform.isAndroid) {
        _dylib = DynamicLibrary.open('libkestrel_core.so');
      } else if (Platform.isWindows) {
        // Look in native_core build dir or app root
        const dllPath = 'native_core/kestrel_core.dll';
        if (File(dllPath).existsSync()) {
          _dylib = DynamicLibrary.open(dllPath);
        } else {
          _dylib = DynamicLibrary.open('kestrel_core.dll');
        }
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libkestrel_core.so');
      } else if (Platform.isMacOS) {
        _dylib = DynamicLibrary.open('libkestrel_core.dylib');
      }

      if (_dylib != null) {
        _classifyFn = _dylib!
            .lookup<NativeFunction<CKestrelClassifyStroke>>('kestrel_classify_stroke')
            .asFunction<DartKestrelClassifyStroke>();
        _smoothFn = _dylib!
            .lookup<NativeFunction<CKestrelSmoothStroke>>('kestrel_smooth_stroke')
            .asFunction<DartKestrelSmoothStroke>();
        _ngonFn = _dylib!
            .lookup<NativeFunction<CKestrelGenerateNgon>>('kestrel_generate_regular_ngon')
            .asFunction<DartKestrelGenerateNgon>();
        _isNativeAvailable = true;
      }
    } catch (_) {
      _isNativeAvailable = false;
    }
  }

  /// Classifies stroke points into geometric primitives or handwriting
  ShapeResult classifyStroke(List<StrokePoint> points) {
    if (points.length < 2) {
      return const ShapeResult(
        type: KestrelShapeType.handwriting,
        confidence: 1.0,
        minX: 0,
        minY: 0,
        width: 0,
        height: 0,
      );
    }

    if (_isNativeAvailable && _classifyFn != null) {
      final arena = malloc;
      try {
        final pArray = arena<CKestrelPoint>(points.length);
        for (var i = 0; i < points.length; ++i) {
          pArray[i].x = points[i].x;
          pArray[i].y = points[i].y;
          pArray[i].pressure = points[i].pressure;
          pArray[i].tilt = points[i].tilt;
          pArray[i].timestamp = points[i].timestamp;
        }

        final pResult = arena<CKestrelClassificationResult>();
        final ok = _classifyFn!(pArray, points.length, pResult);

        if (ok == 1) {
          final res = pResult.ref;
          final shapeType = (res.shapeType >= 0 && res.shapeType < KestrelShapeType.values.length)
              ? KestrelShapeType.values[res.shapeType]
              : KestrelShapeType.handwriting;

          final vertices = <StrokePoint>[];
          for (var i = 0; i < res.vertexCount; ++i) {
            vertices.add(StrokePoint(
              x: res.vertices[i].x,
              y: res.vertices[i].y,
              pressure: res.vertices[i].pressure,
            ));
          }

          return ShapeResult(
            type: shapeType,
            confidence: res.confidence,
            minX: res.bbox.x,
            minY: res.bbox.y,
            width: res.bbox.width,
            height: res.bbox.height,
            centerX: res.centerX,
            centerY: res.centerY,
            radius: res.radius,
            radiusY: res.radiusY,
            p1X: res.p1X,
            p1Y: res.p1Y,
            p2X: res.p2X,
            p2Y: res.p2Y,
            arrowHeadAtP2: res.arrowHeadAtP2 == 1,
            vertices: vertices,
          );
        }
      } finally {
        arena.free(arena<Int8>(0)); // cleanup
      }
    }

    // Pure Dart Fallback if native library is unavailable
    return _dartFallbackClassify(points);
  }

  /// Smooths raw points into Catmull-Rom spline curves
  List<StrokePoint> smoothStroke(List<StrokePoint> points, {double smoothFactor = 1.0}) {
    if (points.length < 3) return points;

    if (_isNativeAvailable && _smoothFn != null) {
      final arena = malloc;
      try {
        final pArray = arena<CKestrelPoint>(points.length);
        for (var i = 0; i < points.length; ++i) {
          pArray[i].x = points[i].x;
          pArray[i].y = points[i].y;
          pArray[i].pressure = points[i].pressure;
          pArray[i].tilt = points[i].tilt;
          pArray[i].timestamp = points[i].timestamp;
        }

        final maxOut = math.min(1000, points.length * 6);
        final outArray = arena<CKestrelPoint>(maxOut);
        final outCountPtr = arena<Int32>();

        final ok = _smoothFn!(pArray, points.length, smoothFactor, outArray, maxOut, outCountPtr);
        if (ok == 1) {
          final count = outCountPtr.value;
          final smoothed = <StrokePoint>[];
          for (var i = 0; i < count; ++i) {
            smoothed.add(StrokePoint(
              x: outArray[i].x,
              y: outArray[i].y,
              pressure: outArray[i].pressure,
              tilt: outArray[i].tilt,
              timestamp: outArray[i].timestamp,
            ));
          }
          return smoothed;
        }
      } finally {
        arena.free(arena<Int8>(0));
      }
    }

    return _dartCatmullRom(points);
  }

  /// Generates a regular n-sided polygon using native core
  List<StrokePoint> generateRegularNgon(double cx, double cy, double radius, int n, {double angleOffset = -math.pi / 2}) {
    if (_isNativeAvailable && _ngonFn != null) {
      final arena = malloc;
      try {
        final outArray = arena<CKestrelPoint>(32);
        final outCountPtr = arena<Int32>();
        final ok = _ngonFn!(cx, cy, radius, n, angleOffset, outArray, outCountPtr);
        if (ok == 1) {
          final count = outCountPtr.value;
          final verts = <StrokePoint>[];
          for (var i = 0; i < count; ++i) {
            verts.add(StrokePoint(x: outArray[i].x, y: outArray[i].y));
          }
          return verts;
        }
      } finally {
        arena.free(arena<Int8>(0));
      }
    }

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

  // Pure Dart Fallback Implementation
  ShapeResult _dartFallbackClassify(List<StrokePoint> points) {
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

    // Directness check for line
    if (totalLen > 20 && (startEndDist / totalLen) > 0.90) {
      return ShapeResult(
        type: KestrelShapeType.line,
        confidence: 0.90,
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

    return ShapeResult(
      type: KestrelShapeType.handwriting,
      confidence: 1.0,
      minX: minX,
      minY: minY,
      width: w,
      height: h,
    );
  }

  List<StrokePoint> _dartCatmullRom(List<StrokePoint> points) {
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
}
