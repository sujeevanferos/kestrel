import 'package:flutter/material.dart';
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
  Map<String, dynamic> toJson();
}

class InkStrokeItem extends CanvasItem {
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  InkStrokeItem({
    required super.id,
    super.x = 0,
    super.y = 0,
    super.isSelected = false,
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

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ink_stroke',
    'id': id,
    'color': color.toARGB32(),
    'strokeWidth': strokeWidth,
    'isHighlighter': isHighlighter,
    'points': points.map((p) => {'x': p.x, 'y': p.y, 'p': p.pressure, 't': p.tilt}).toList(),
  };

  factory InkStrokeItem.fromJson(Map<String, dynamic> json) {
    return InkStrokeItem(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isHighlighter: json['isHighlighter'] as bool? ?? false,
      points: (json['points'] as List<dynamic>)
          .map((p) => StrokePoint(
                x: (p['x'] as num).toDouble(),
                y: (p['y'] as num).toDouble(),
                pressure: (p['p'] as num?)?.toDouble() ?? 1.0,
                tilt: (p['t'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList(),
    );
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
    super.x = 0,
    super.y = 0,
    super.isSelected = false,
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

  @override
  Map<String, dynamic> toJson() => {
    'type': 'smart_shape',
    'id': id,
    'shapeType': shapeType.index,
    'bounds': [bounds.left, bounds.top, bounds.right, bounds.bottom],
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor?.toARGB32(),
    'strokeWidth': strokeWidth,
    'p1': p1 != null ? [p1!.dx, p1!.dy] : null,
    'p2': p2 != null ? [p2!.dx, p2!.dy] : null,
    'arrowHeadAtP2': arrowHeadAtP2,
    'vertices': vertices.map((v) => {'x': v.x, 'y': v.y}).toList(),
  };

  factory SmartShapeCanvasItem.fromJson(Map<String, dynamic> json) {
    final b = (json['bounds'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
    final p1List = json['p1'] as List<dynamic>?;
    final p2List = json['p2'] as List<dynamic>?;
    final vertList = (json['vertices'] as List<dynamic>?) ?? [];

    return SmartShapeCanvasItem(
      id: json['id'] as String,
      shapeType: KestrelShapeType.values[(json['shapeType'] as int).clamp(0, KestrelShapeType.values.length - 1)],
      bounds: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: json['fillColor'] != null ? Color(json['fillColor'] as int) : null,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      p1: p1List != null ? Offset((p1List[0] as num).toDouble(), (p1List[1] as num).toDouble()) : null,
      p2: p2List != null ? Offset((p2List[0] as num).toDouble(), (p2List[1] as num).toDouble()) : null,
      arrowHeadAtP2: json['arrowHeadAtP2'] as bool? ?? true,
      vertices: vertList.map((v) => StrokePoint(x: (v['x'] as num).toDouble(), y: (v['y'] as num).toDouble())).toList(),
    );
  }
}

/// Floating Paper Sticky Note on Canvas
class StickyNoteItem extends CanvasItem {
  double width;
  double height;
  String text;
  Color noteColor;

  StickyNoteItem({
    required super.id,
    super.x = 100,
    super.y = 100,
    super.isSelected = false,
    this.width = 240,
    this.height = 200,
    this.text = '',
    this.noteColor = const Color(0xFFFEF3C7), // Warm Amber Cream
  });

  @override
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  @override
  void paint(Canvas canvas) {
    // Custom painting fallback if rendered purely on canvas
    final rrect = RRect.fromRectAndRadius(boundingBox, const Radius.circular(8));
    final fillPaint = Paint()..color = noteColor;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRRect(rrect.shift(const Offset(2, 3)), shadowPaint);
    canvas.drawRRect(rrect, fillPaint);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'sticky_note',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'text': text,
    'noteColor': noteColor.toARGB32(),
  };

  factory StickyNoteItem.fromJson(Map<String, dynamic> json) => StickyNoteItem(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 240,
    height: (json['height'] as num?)?.toDouble() ?? 200,
    text: json['text'] as String? ?? '',
    noteColor: Color(json['noteColor'] as int? ?? 0xFFFEF3C7),
  );
}

/// Free-Form Movable Typography Text Box
class TextBoxItem extends CanvasItem {
  double width;
  double height;
  String text;
  double fontSize;
  Color textColor;
  bool isBold;

  TextBoxItem({
    required super.id,
    super.x = 100,
    super.y = 100,
    super.isSelected = false,
    this.width = 260,
    this.height = 100,
    this.text = '',
    this.fontSize = 18.0,
    this.textColor = const Color(0xFF1B1C1E),
    this.isBold = false,
  });

  @override
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  @override
  void paint(Canvas canvas) {
    // Fallback paint
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text_box',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'text': text,
    'fontSize': fontSize,
    'textColor': textColor.toARGB32(),
    'isBold': isBold,
  };

  factory TextBoxItem.fromJson(Map<String, dynamic> json) => TextBoxItem(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 260,
    height: (json['height'] as num?)?.toDouble() ?? 100,
    text: json['text'] as String? ?? '',
    fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
    textColor: Color(json['textColor'] as int? ?? 0xFF1B1C1E),
    isBold: json['isBold'] as bool? ?? false,
  );
}

/// Interactive Dynamic Grid Table on Canvas
class TableItem extends CanvasItem {
  int rows;
  int cols;
  double colWidth;
  double rowHeight;
  Map<String, String> cells; // key: "row,col"

  TableItem({
    required super.id,
    super.x = 100,
    super.y = 100,
    super.isSelected = false,
    this.rows = 3,
    this.cols = 3,
    this.colWidth = 110,
    this.rowHeight = 44,
    Map<String, String>? cells,
  }) : cells = cells ?? {};

  double get width => cols * colWidth;
  double get height => rows * rowHeight;

  @override
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  @override
  void paint(Canvas canvas) {
    final borderPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(boundingBox, const Radius.circular(6));
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'table',
    'id': id,
    'x': x,
    'y': y,
    'rows': rows,
    'cols': cols,
    'colWidth': colWidth,
    'rowHeight': rowHeight,
    'cells': cells,
  };

  factory TableItem.fromJson(Map<String, dynamic> json) => TableItem(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    rows: (json['rows'] as int?) ?? 3,
    cols: (json['cols'] as int?) ?? 3,
    colWidth: (json['colWidth'] as num?)?.toDouble() ?? 110,
    rowHeight: (json['rowHeight'] as num?)?.toDouble() ?? 44,
    cells: (json['cells'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
  );
}

/// In-Canvas Picture-in-Picture Lesson Video Player Card
class VideoFloatItem extends CanvasItem {
  double width;
  double height;
  final String videoPath;
  final String title;
  bool isPlaying;
  double progress;

  VideoFloatItem({
    required super.id,
    super.x = 100,
    super.y = 100,
    super.isSelected = false,
    this.width = 480,
    this.height = 300,
    required this.videoPath,
    this.title = 'Lesson Presentation',
    this.isPlaying = false,
    this.progress = 0.0,
  });

  @override
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  @override
  void paint(Canvas canvas) {}

  @override
  Map<String, dynamic> toJson() => {
    'type': 'video_float',
    'id': id,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'videoPath': videoPath,
    'title': title,
    'progress': progress,
  };

  factory VideoFloatItem.fromJson(Map<String, dynamic> json) => VideoFloatItem(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 480,
    height: (json['height'] as num?)?.toDouble() ?? 300,
    videoPath: json['videoPath'] as String? ?? '',
    title: json['title'] as String? ?? 'Lesson Video',
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Helper deserializer for polymorphic CanvasItem JSON
CanvasItem? deserializeCanvasItem(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'ink_stroke':
      return InkStrokeItem.fromJson(json);
    case 'smart_shape':
      return SmartShapeCanvasItem.fromJson(json);
    case 'sticky_note':
      return StickyNoteItem.fromJson(json);
    case 'text_box':
      return TextBoxItem.fromJson(json);
    case 'table':
      return TableItem.fromJson(json);
    case 'video_float':
      return VideoFloatItem.fromJson(json);
    default:
      return null;
  }
}
