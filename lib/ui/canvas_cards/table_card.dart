import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../canvas/models/canvas_item.dart';

class TableCard extends StatelessWidget {
  final TableItem item;
  final CanvasController controller;

  const TableCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final zoom = controller.zoomLevel;
    final isSelected = controller.selectedItemId == item.id;

    return Container(
      width: item.width * zoom,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6 * zoom),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B1C1E) : const Color(0xFFE5E7EB),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Header
          GestureDetector(
            onPanDown: (_) => controller.selectItem(item.id),
            onPanUpdate: (details) {
              final newX = item.x + details.delta.dx / zoom;
              final newY = item.y + details.delta.dy / zoom;
              controller.updateItemPosition(item.id, Offset(newX, newY));
            },
            child: Container(
              height: 28 * zoom,
              padding: EdgeInsets.symmetric(horizontal: 8 * zoom),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5 * zoom)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.table, size: 13 * zoom, color: const Color(0xFF4B5563)),
                  SizedBox(width: 6 * zoom),
                  Text(
                    '${item.rows}x${item.cols} Table',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11 * zoom,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => controller.deleteItem(item.id),
                    child: Icon(LucideIcons.x, size: 13 * zoom, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
          // Cells Grid
          for (var r = 0; r < item.rows; ++r)
            Container(
              height: item.rowHeight * zoom,
              decoration: BoxDecoration(
                color: r == 0 ? const Color(0xFFF9FAFB) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE5E7EB),
                    width: r == 0 ? 1.5 : 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  for (var c = 0; c < item.cols; ++c)
                    Expanded(
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: c < item.cols - 1 ? const Color(0xFFE5E7EB) : Colors.transparent,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 6 * zoom),
                        alignment: Alignment.center,
                        child: TextFormField(
                          initialValue: item.cells['$r,$c'] ?? '',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12 * zoom,
                            fontWeight: r == 0 ? FontWeight.w600 : FontWeight.normal,
                            color: const Color(0xFF1B1C1E),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            controller.updateTableCell(item.id, r, c, val);
                          },
                          onTap: () => controller.selectItem(item.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
