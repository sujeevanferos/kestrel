import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../canvas/models/canvas_item.dart';

class TextBoxCard extends StatefulWidget {
  final TextBoxItem item;
  final CanvasController controller;

  const TextBoxCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<TextBoxCard> createState() => _TextBoxCardState();
}

class _TextBoxCardState extends State<TextBoxCard> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(covariant TextBoxCard oldWidget) {
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
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6 * zoom),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B1C1E) : Colors.black.withValues(alpha: 0.12),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6 * zoom,
            offset: Offset(1 * zoom, 2 * zoom),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Header & Formatting Controls
          GestureDetector(
            onPanDown: (_) => widget.controller.selectItem(widget.item.id),
            onPanUpdate: (details) {
              final newX = widget.item.x + details.delta.dx / zoom;
              final newY = widget.item.y + details.delta.dy / zoom;
              widget.controller.updateItemPosition(widget.item.id, Offset(newX, newY));
            },
            child: Container(
              height: 28 * zoom,
              padding: EdgeInsets.symmetric(horizontal: 6 * zoom),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5 * zoom)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.type, size: 13 * zoom, color: const Color(0xFF4B5563)),
                  SizedBox(width: 6 * zoom),
                  // Font size minus
                  GestureDetector(
                    onTap: () {
                      final newSize = (widget.item.fontSize - 2).clamp(10.0, 48.0);
                      widget.controller.updateTextBox(widget.item.id, fontSize: newSize);
                    },
                    child: Icon(LucideIcons.minus, size: 12 * zoom, color: const Color(0xFF6B7280)),
                  ),
                  SizedBox(width: 4 * zoom),
                  Text(
                    '${widget.item.fontSize.toInt()}pt',
                    style: TextStyle(fontSize: 10 * zoom, color: const Color(0xFF374151)),
                  ),
                  SizedBox(width: 4 * zoom),
                  // Font size plus
                  GestureDetector(
                    onTap: () {
                      final newSize = (widget.item.fontSize + 2).clamp(10.0, 48.0);
                      widget.controller.updateTextBox(widget.item.id, fontSize: newSize);
                    },
                    child: Icon(LucideIcons.plus, size: 12 * zoom, color: const Color(0xFF6B7280)),
                  ),
                  SizedBox(width: 8 * zoom),
                  // Bold toggle
                  GestureDetector(
                    onTap: () {
                      widget.controller.updateTextBox(widget.item.id, isBold: !widget.item.isBold);
                    },
                    child: Icon(
                      LucideIcons.bold,
                      size: 12 * zoom,
                      color: widget.item.isBold ? const Color(0xFF1B1C1E) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const Spacer(),
                  // Delete
                  GestureDetector(
                    onTap: () => widget.controller.deleteItem(widget.item.id),
                    child: Icon(LucideIcons.x, size: 13 * zoom, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
          // Text Input
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(6 * zoom),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: widget.item.fontSize * zoom,
                  fontWeight: widget.item.isBold ? FontWeight.bold : FontWeight.normal,
                  color: widget.item.textColor,
                  height: 1.3,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter text...',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  widget.controller.updateTextBox(widget.item.id, text: val);
                },
                onTap: () => widget.controller.selectItem(widget.item.id),
              ),
            ),
          ),
          // Resize Handle
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newW = widget.item.width + details.delta.dx / zoom;
                final newH = widget.item.height + details.delta.dy / zoom;
                widget.controller.updateItemSize(widget.item.id, newW, newH);
              },
              child: Padding(
                padding: EdgeInsets.all(3 * zoom),
                child: Icon(
                  LucideIcons.cornerDownRight,
                  size: 11 * zoom,
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
