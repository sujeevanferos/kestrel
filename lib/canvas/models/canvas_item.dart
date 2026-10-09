import 'dart:ui';
import '../../core/native_bindings.dart';

abstract class CanvasItem {
  final String id;
  double x;
  double y;
  bool isSelected;

  CanvasItem({
    required this.id,
    this.x = 0,
    this.y = 0,
    this.isSelected = false,
  });

  Rect get boundingBox;
  void paint(Canvas canvas);
}

class InkStrokeItem extends CanvasItem {
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  InkStrokeItem({
    required super.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
  });

  @override
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    var minX = points.first.x, maxX = points.first.x;
    var minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return Rect.fromLTRB(
      minX - strokeWidth,
      minY - strokeWidth,
      maxX + strokeWidth,
      maxY + strokeWidth,
    );
  }

  @override
  void paint(Canvas canvas) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = isHighlighter ? color.withValues(alpha: 0.35) : color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(Offset(points.first.x, points.first.y), strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; ++i) {
      path.lineTo(points[i].x, points[i].y);
    }
    canvas.drawPath(path, paint);
  }
}

class SmartShapeCanvasItem extends CanvasItem {
  final KestrelShapeType shapeType;
  final Rect bounds;
  final Color strokeColor;
  final Color? fillColor;
  final double strokeWidth;
  final List<StrokePoint> vertices;
  final Offset? p1;
  final Offset? p2;
  final bool arrowHeadAtP2;

  SmartShapeCanvasItem({
    required super.id,
    required this.shapeType,
    required this.bounds,
    required this.strokeColor,
    this.fillColor,
    required this.strokeWidth,
    this.vertices = const [],
    this.p1,
    this.p2,
    this.arrowHeadAtP2 = true,
  });

  @override
  Rect get boundingBox => bounds.inflate(strokeWidth);

  @override
  void paint(Canvas canvas) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = fillColor != null
        ? (Paint()
          ..color = fillColor!
          ..style = PaintingStyle.fill)
        : null;

    switch (shapeType) {
      case KestrelShapeType.line:
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1!, p2!, strokePaint);
        }
        break;

      case KestrelShapeType.arrow:
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1!, p2!, strokePaint);
          final tip = arrowHeadAtP2 ? p2! : p1!;
          final base = arrowHeadAtP2 ? p1! : p2!;
          final dx = tip.dx - base.dx;
          final dy = tip.dy - base.dy;
          final len = (dx * dx + dy * dy);
          if (len > 1.0) {
            final angle = (Offset(dx, dy)).direction;
            const arrowLen = 16.0;
            const arrowAngle = 0.523599; // 30 deg in radians
            final pLeft = tip - Offset.fromDirection(angle - arrowAngle, arrowLen);
            final pRight = tip - Offset.fromDirection(angle + arrowAngle, arrowLen);
            final arrowPath = Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(pLeft.dx, pLeft.dy)
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(pRight.dx, pRight.dy);
            canvas.drawPath(arrowPath, strokePaint);
          }
        }
        break;

      case KestrelShapeType.circle:
      case KestrelShapeType.ellipse:
        if (fillPaint != null) canvas.drawOval(bounds, fillPaint);
        canvas.drawOval(bounds, strokePaint);
        break;

      case KestrelShapeType.rectangle:
      case KestrelShapeType.square:
        if (fillPaint != null) canvas.drawRect(bounds, fillPaint);
        canvas.drawRect(bounds, strokePaint);
        break;

      case KestrelShapeType.triangle:
      case KestrelShapeType.cloud:
        if (vertices.isNotEmpty) {
          final path = Path()..moveTo(vertices.first.x, vertices.first.y);
          for (var i = 1; i < vertices.length; ++i) {
            path.lineTo(vertices[i].x, vertices[i].y);
          }
          path.close();
          if (fillPaint != null) canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
        }
        break;

      default:
        break;
    }
  }
}
