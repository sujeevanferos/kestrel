// Shared models and interface for both native (FFI) and web (pure Dart) platforms

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
