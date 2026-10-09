import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../canvas/models/canvas_item.dart';

class StickyNoteCard extends StatefulWidget {
  final StickyNoteItem item;
  final CanvasController controller;

  const StickyNoteCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<StickyNoteCard> createState() => _StickyNoteCardState();
}

class _StickyNoteCardState extends State<StickyNoteCard> {
  late final TextEditingController _textController;

  static const List<Color> _palette = [
    Color(0xFFFEF3C7), // Warm Amber Cream
    Color(0xFFD1FAE5), // Mint Sage
    Color(0xFFFFE4E6), // Rose Blush
    Color(0xFFE0F2FE), // Sky Blue
    Color(0xFFEDE9FE), // Lavender
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(covariant StickyNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text && _textController.text != widget.item.text) {
      _textController.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = widget.controller.zoomLevel;
    final isSelected = widget.controller.selectedItemId == widget.item.id;

    return Container(
      width: widget.item.width * zoom,
      height: widget.item.height * zoom,
      decoration: BoxDecoration(
        color: widget.item.noteColor,
        borderRadius: BorderRadius.circular(8 * zoom),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B1C1E) : Colors.black.withValues(alpha: 0.1),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8 * zoom,
            offset: Offset(2 * zoom, 4 * zoom),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Drag handle & Controls
          GestureDetector(
            onPanDown: (_) => widget.controller.selectItem(widget.item.id),
            onPanUpdate: (details) {
              final newX = widget.item.x + details.delta.dx / zoom;
              final newY = widget.item.y + details.delta.dy / zoom;
              widget.controller.updateItemPosition(widget.item.id, Offset(newX, newY));
            },
            child: Container(
              height: 32 * zoom,
              padding: EdgeInsets.symmetric(horizontal: 8 * zoom),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.vertical(top: Radius.circular(7 * zoom)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.gripHorizontal, size: 14 * zoom, color: const Color(0xFF6B7280)),
                  const Spacer(),
                  // Color picker dots
                  for (final color in _palette)
                    GestureDetector(
                      onTap: () => widget.controller.updateStickyNoteColor(widget.item.id, color),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2 * zoom),
                        width: 12 * zoom,
                        height: 12 * zoom,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: 6 * zoom),
                  // Delete button
                  GestureDetector(
                    onTap: () => widget.controller.deleteItem(widget.item.id),
                    child: Icon(LucideIcons.x, size: 14 * zoom, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
          // Editable Text Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8 * zoom),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14 * zoom,
                  color: const Color(0xFF1B1C1E),
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your note...',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  widget.controller.updateStickyNoteText(widget.item.id, val);
                },
                onTap: () => widget.controller.selectItem(widget.item.id),
              ),
            ),
          ),
          // Bottom-right Resize Handle
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newW = widget.item.width + details.delta.dx / zoom;
                final newH = widget.item.height + details.delta.dy / zoom;
                widget.controller.updateItemSize(widget.item.id, newW, newH);
              },
              child: Padding(
                padding: EdgeInsets.all(4 * zoom),
                child: Icon(
                  LucideIcons.cornerDownRight,
                  size: 12 * zoom,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
