import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/native_bindings.dart';
import 'canvas_controller.dart';
import 'models/canvas_item.dart';

class WhiteboardCanvas extends StatelessWidget {
  final CanvasController controller;

  const WhiteboardCanvas({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          color: _getBackgroundColor(controller.paperStyle),
          child: Stack(
            children: [
              // Custom Grid / Paper Texture Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: _PaperBackgroundPainter(
                    style: controller.paperStyle,
                    panOffset: controller.panOffset,
                    zoomLevel: controller.zoomLevel,
                  ),
                ),
              ),

              // Interactive Stroke Input & Items Rendering Layer
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    final scenePos = _viewportToScene(event.localPosition);
                    controller.onPointerDown(scenePos, event.pressure, event.tilt);
                  },
                  onPointerMove: (event) {
                    final scenePos = _viewportToScene(event.localPosition);
                    controller.onPointerMove(scenePos, event.pressure, event.tilt);
                  },
                  onPointerUp: (event) {
                    controller.onPointerUp();
                  },
                  onPointerCancel: (event) {
                    controller.onPointerUp();
                  },
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      // Mouse wheel / trackpad pinch zoom
                      final zoomDelta = event.scrollDelta.dy > 0 ? 0.90 : 1.10;
                      controller.updatePanAndZoom(Offset.zero, zoomDelta, event.localPosition);
                    }
                  },
                  child: CustomPaint(
                    painter: _WhiteboardPainter(
                      items: controller.items,
                      activePoints: controller.activePoints,
                      currentTool: controller.currentTool,
                      currentColor: controller.currentColor,
                      strokeWidth: controller.strokeWidth,
                      panOffset: controller.panOffset,
                      zoomLevel: controller.zoomLevel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Offset _viewportToScene(Offset viewportPos) {
    return (viewportPos - controller.panOffset) / controller.zoomLevel;
  }

  Color _getBackgroundColor(PaperStyle style) {
    switch (style) {
      case PaperStyle.ivoryPlain:
      case PaperStyle.engineeringGrid:
      case PaperStyle.dotGrid:
        return const Color(0xFFFBF8F2); // Warm Ivory
      case PaperStyle.darkChalkboard:
        return const Color(0xFF1E2421); // Dark Slate Chalkboard
    }
  }
}

// -----------------------------------------------------------------------------
// PAPER BACKGROUND PAINTER (RULING / GRIDS)
// -----------------------------------------------------------------------------

class _PaperBackgroundPainter extends CustomPainter {
  final PaperStyle style;
  final Offset panOffset;
  final double zoomLevel;

  _PaperBackgroundPainter({
    required this.style,
    required this.panOffset,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (style == PaperStyle.ivoryPlain) return;

    final gridPaint = Paint()
      ..color = (style == PaperStyle.darkChalkboard)
          ? const Color(0x1FFFFFFF)
          : const Color(0xFFE8E2D5)
      ..strokeWidth = 1.0;

    const baseSpacing = 32.0;
    final spacing = baseSpacing * zoomLevel;

    if (spacing < 10.0) return; // Prevent excessive rendering when zoomed out

    final startX = (panOffset.dx % spacing);
    final startY = (panOffset.dy % spacing);

    if (style == PaperStyle.engineeringGrid || style == PaperStyle.darkChalkboard) {
      // Vertical grid lines
      for (var x = startX; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      // Horizontal grid lines
      for (var y = startY; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    } else if (style == PaperStyle.dotGrid) {
      // Dot matrix
      for (var x = startX; x < size.width; x += spacing) {
        for (var y = startY; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2 * zoomLevel.clamp(0.5, 2.0), gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBackgroundPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

// -----------------------------------------------------------------------------
// CANVAS ITEMS & LIVE STROKE PAINTER
// -----------------------------------------------------------------------------

class _WhiteboardPainter extends CustomPainter {
  final List<CanvasItem> items;
  final List<StrokePoint> activePoints;
  final CanvasTool currentTool;
  final Color currentColor;
  final double strokeWidth;
  final Offset panOffset;
  final double zoomLevel;

  _WhiteboardPainter({
    required this.items,
    required this.activePoints,
    required this.currentTool,
    required this.currentColor,
    required this.strokeWidth,
    required this.panOffset,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel, zoomLevel);

    // Draw all committed canvas items
    for (final item in items) {
      item.paint(canvas);
    }

    // Draw active in-progress stroke with live feedback
    if (activePoints.isNotEmpty && currentTool != CanvasTool.eraser) {
      final isHighlighter = currentTool == CanvasTool.highlighter;
      final livePaint = Paint()
        ..color = isHighlighter ? currentColor.withValues(alpha: 0.35) : currentColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (activePoints.length == 1) {
        canvas.drawCircle(
          Offset(activePoints.first.x, activePoints.first.y),
          strokeWidth / 2,
          livePaint,
        );
      } else {
        final path = Path()..moveTo(activePoints.first.x, activePoints.first.y);
        for (var i = 1; i < activePoints.length; ++i) {
          path.lineTo(activePoints[i].x, activePoints[i].y);
        }
        canvas.drawPath(path, livePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true; // Always repaint during active drawing gestures
  }
}
