import 'dart:ui' show PointMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/native_bindings.dart';
import '../ui/canvas_cards/sticky_note_card.dart';
import '../ui/canvas_cards/table_card.dart';
import '../ui/canvas_cards/text_box_card.dart';
import '../ui/canvas_cards/video_float_card.dart';
import 'canvas_controller.dart';
import 'models/canvas_item.dart';

class WhiteboardCanvas extends StatelessWidget {
  final CanvasController controller;
  final void Function(List<CanvasItem> selectedItems)? onGeneratePdf;
  final void Function(List<CanvasItem> selectedItems)? onGenerateVideo;

  const WhiteboardCanvas({
    super.key,
    required this.controller,
    this.onGeneratePdf,
    this.onGenerateVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selectedItems = controller.getSelectedItems();
        Rect? combinedSelectedBounds;
        if (controller.hasActiveSelection && selectedItems.isNotEmpty) {
          combinedSelectedBounds = selectedItems.first.boundingBox;
          for (final it in selectedItems) {
            combinedSelectedBounds = combinedSelectedBounds!.expandToInclude(it.boundingBox);
          }
        }

        return Container(
          color: _getBackgroundColor(controller.paperStyle),
          child: Stack(
            clipBehavior: Clip.none,
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

              // Interactive Stroke Input, Items & Selection Rendering Layer
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
                      items: controller.items.where((it) => it is InkStrokeItem || it is SmartShapeCanvasItem).toList(),
                      activePoints: controller.activePoints,
                      currentTool: controller.currentTool,
                      currentColor: controller.currentColor,
                      strokeWidth: controller.strokeWidth,
                      panOffset: controller.panOffset,
                      zoomLevel: controller.zoomLevel,
                      selectionMarquee: controller.selectionMarquee,
                      lassoPoints: controller.activeLassoPoints,
                      selectedItemIds: controller.selectedItemIds,
                    ),
                  ),
                ),
              ),

              // Floating Interactive Cards Layer (Sticky Notes, Text Boxes, Tables, Videos)
              for (final item in controller.items) ...[
                if (item is StickyNoteItem)
                  Positioned(
                    left: controller.panOffset.dx + (item.x * controller.zoomLevel),
                    top: controller.panOffset.dy + (item.y * controller.zoomLevel),
                    child: StickyNoteCard(item: item, controller: controller),
                  )
                else if (item is TextBoxItem)
                  Positioned(
                    left: controller.panOffset.dx + (item.x * controller.zoomLevel),
                    top: controller.panOffset.dy + (item.y * controller.zoomLevel),
                    child: TextBoxCard(item: item, controller: controller),
                  )
                else if (item is TableItem)
                  Positioned(
                    left: controller.panOffset.dx + (item.x * controller.zoomLevel),
                    top: controller.panOffset.dy + (item.y * controller.zoomLevel),
                    child: TableCard(item: item, controller: controller),
                  )
                else if (item is VideoFloatItem)
                  Positioned(
                    left: controller.panOffset.dx + (item.x * controller.zoomLevel),
                    top: controller.panOffset.dy + (item.y * controller.zoomLevel),
                    child: VideoFloatCard(item: item, controller: controller),
                  ),
              ],

              // Quick Action Bar above active selection
              if (controller.hasActiveSelection && combinedSelectedBounds != null)
                Positioned(
                  left: controller.panOffset.dx + (combinedSelectedBounds.center.dx * controller.zoomLevel) - 160,
                  top: controller.panOffset.dy + (combinedSelectedBounds.top * controller.zoomLevel) - 48,
                  child: _SelectionActionBar(
                    selectedCount: selectedItems.length,
                    onGeneratePdf: () => onGeneratePdf?.call(selectedItems),
                    onGenerateVideo: () => onGenerateVideo?.call(selectedItems),
                    onDelete: controller.deleteSelectedItems,
                    onDeselect: controller.clearSelection,
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
        return const Color(0xFFFBF8F2); // Warm Ivory Paper
      case PaperStyle.darkChalkboard:
        return const Color(0xFF1E242B); // Classroom Slate Charcoal
    }
  }
}

// -----------------------------------------------------------------------------
// FLOATING SELECTION ACTION PILL
// -----------------------------------------------------------------------------

class _SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onGeneratePdf;
  final VoidCallback onGenerateVideo;
  final VoidCallback onDelete;
  final VoidCallback onDeselect;

  const _SelectionActionBar({
    required this.selectedCount,
    required this.onGeneratePdf,
    required this.onGenerateVideo,
    required this.onDelete,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1C1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          // PDF button
          InkWell(
            onTap: onGeneratePdf,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                children: [
                  Icon(LucideIcons.fileText, size: 13, color: Color(0xFF60A5FA)),
                  SizedBox(width: 4),
                  Text('PDF', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Video button
          InkWell(
            onTap: onGenerateVideo,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                children: [
                  Icon(LucideIcons.video, size: 13, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text('Video', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 13, color: Color(0xFFEF4444)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: onDelete,
          ),
          // Deselect
          IconButton(
            icon: const Icon(LucideIcons.x, size: 13, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: onDeselect,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAPER BACKGROUND PAINTER
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

    final isDark = style == PaperStyle.darkChalkboard;
    final gridColor = isDark
        ? const Color(0xFF2C3440).withValues(alpha: 0.6)
        : const Color(0xFFE2DDD2).withValues(alpha: 0.7);

    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const baseSpacing = 32.0;
    final spacing = baseSpacing * zoomLevel;

    if (spacing < 8.0) return;

    final startX = panOffset.dx % spacing;
    final startY = panOffset.dy % spacing;

    if (style == PaperStyle.engineeringGrid || style == PaperStyle.darkChalkboard) {
      for (var x = startX; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
      for (var y = startY; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    } else if (style == PaperStyle.dotGrid) {
      final dotPaint = Paint()
        ..color = gridColor
        ..strokeWidth = (1.5 * zoomLevel).clamp(1.0, 3.0)
        ..strokeCap = StrokeCap.round;

      for (var x = startX; x < size.width; x += spacing) {
        for (var y = startY; y < size.height; y += spacing) {
          canvas.drawPoints(PointMode.points, [Offset(x, y)], dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBackgroundPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.style != style;
  }
}

// -----------------------------------------------------------------------------
// CANVAS ITEMS & LIVE STROKE / SELECTION PAINTER
// -----------------------------------------------------------------------------

class _WhiteboardPainter extends CustomPainter {
  final List<CanvasItem> items;
  final List<StrokePoint> activePoints;
  final CanvasTool currentTool;
  final Color currentColor;
  final double strokeWidth;
  final Offset panOffset;
  final double zoomLevel;
  final Rect? selectionMarquee;
  final List<Offset> lassoPoints;
  final Set<String> selectedItemIds;

  _WhiteboardPainter({
    required this.items,
    required this.activePoints,
    required this.currentTool,
    required this.currentColor,
    required this.strokeWidth,
    required this.panOffset,
    required this.zoomLevel,
    this.selectionMarquee,
    this.lassoPoints = const [],
    this.selectedItemIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoomLevel, zoomLevel);

    // Draw all committed canvas items
    for (final item in items) {
      item.paint(canvas);

      // Highlight selected items
      if (selectedItemIds.contains(item.id)) {
        final highlightPaint = Paint()
          ..color = const Color(0xFF3B82F6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRRect(
          RRect.fromRectAndRadius(item.boundingBox.inflate(4), const Radius.circular(6)),
          highlightPaint,
        );
      }
    }

    // Draw active in-progress stroke with live feedback
    if (activePoints.isNotEmpty &&
        currentTool != CanvasTool.eraser &&
        currentTool != CanvasTool.rectangleSelect &&
        currentTool != CanvasTool.lassoSelect) {
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

    // Draw Active Rectangle Selection Marquee
    if (selectionMarquee != null) {
      final fillPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRect(selectionMarquee!, fillPaint);
      canvas.drawRect(selectionMarquee!, strokePaint);
    }

    // Draw Active Freehand Lasso Path
    if (lassoPoints.length > 1) {
      final path = Path()..moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (var i = 1; i < lassoPoints.length; ++i) {
        path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }

      final strokePaint = Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final fillPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) => true;
}
