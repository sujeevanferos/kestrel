import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';

class FloatingToolbar extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onOpenMenu;
  final VoidCallback? onGeneratePdf;
  final VoidCallback? onGenerateVideo;

  const FloatingToolbar({
    super.key,
    required this.controller,
    required this.onOpenMenu,
    this.onGeneratePdf,
    this.onGenerateVideo,
  });

  static const List<Color> _palette = [
    Color(0xFF1B1C1E), // Archival Carbon Black
    Color(0xFF1E3A8A), // Fountain Pen Blue
    Color(0xFFB91C1C), // Crimson Editorial
    Color(0xFF2D6A4F), // Sage Botanical Green
    Color(0xFFD97706), // Ochre Amber
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSelecting = controller.currentTool == CanvasTool.rectangleSelect ||
            controller.currentTool == CanvasTool.lassoSelect;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4EE), // Warm parchment
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFE2DCD0), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3-Bar Menu Button
              _ToolButton(
                icon: LucideIcons.menu,
                tooltip: 'Workspace Menu',
                isSelected: false,
                onPressed: onOpenMenu,
              ),

              const _VerticalDivider(),

              // Pen Tool
              _ToolButton(
                icon: LucideIcons.penTool,
                tooltip: 'Ink Pen',
                isSelected: controller.currentTool == CanvasTool.pen,
                onPressed: () => controller.setTool(CanvasTool.pen),
              ),

              // Highlighter Tool
              _ToolButton(
                icon: LucideIcons.highlighter,
                tooltip: 'Highlighter',
                isSelected: controller.currentTool == CanvasTool.highlighter,
                onPressed: () => controller.setTool(CanvasTool.highlighter),
              ),

              // Eraser Tool
              _ToolButton(
                icon: LucideIcons.eraser,
                tooltip: 'Eraser',
                isSelected: controller.currentTool == CanvasTool.eraser,
                onPressed: () => controller.setTool(CanvasTool.eraser),
              ),

              const _VerticalDivider(),

              // Selection Tools (Rectangle Marquee & Freehand Lasso)
              PopupMenuButton<CanvasTool>(
                tooltip: 'Selection Tool (Rectangle / Lasso)',
                icon: Icon(
                  controller.currentTool == CanvasTool.lassoSelect
                      ? LucideIcons.lasso
                      : LucideIcons.boxSelect,
                  size: 18,
                  color: isSelecting ? const Color(0xFF3B82F6) : const Color(0xFF4A4E57),
                ),
                color: const Color(0xFFF7F4EE),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2DCD0)),
                ),
                onSelected: (tool) => controller.setTool(tool),
                itemBuilder: (context) => [
                  PopupMenuItem<CanvasTool>(
                    value: CanvasTool.rectangleSelect,
                    child: Row(
                      children: [
                        Icon(LucideIcons.boxSelect,
                            size: 16,
                            color: controller.currentTool == CanvasTool.rectangleSelect
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF374151)),
                        const SizedBox(width: 12),
                        Text(
                          'Rectangle Selection',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: controller.currentTool == CanvasTool.rectangleSelect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<CanvasTool>(
                    value: CanvasTool.lassoSelect,
                    child: Row(
                      children: [
                        Icon(LucideIcons.lasso,
                            size: 16,
                            color: controller.currentTool == CanvasTool.lassoSelect
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF374151)),
                        const SizedBox(width: 12),
                        Text(
                          'Freehand Lasso Selection',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: controller.currentTool == CanvasTool.lassoSelect
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Generate Academic PDF Tool
              _ToolButton(
                icon: LucideIcons.fileText,
                tooltip: controller.hasActiveSelection
                    ? 'Generate Academic PDF from Selection'
                    : 'Generate Academic PDF from Whiteboard',
                isSelected: false,
                accentColor: const Color(0xFF2563EB),
                onPressed: () => onGeneratePdf?.call(),
              ),

              // Generate Pedagogical Video Tool
              _ToolButton(
                icon: LucideIcons.video,
                tooltip: controller.hasActiveSelection
                    ? 'Generate Lesson Video from Selection'
                    : 'Generate Lesson Video from Whiteboard',
                isSelected: false,
                accentColor: const Color(0xFFD97706),
                onPressed: () => onGenerateVideo?.call(),
              ),

              const _VerticalDivider(),

              // Insert Floating Cards Menu (Sticky Notes, Text, Tables)
              PopupMenuButton<String>(
                tooltip: 'Insert Card / Object',
                icon: const Icon(LucideIcons.plusSquare, size: 18, color: Color(0xFF4A4E57)),
                color: const Color(0xFFF7F4EE),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2DCD0)),
                ),
                onSelected: (val) {
                  switch (val) {
                    case 'sticky':
                      controller.addStickyNote();
                      break;
                    case 'textbox':
                      controller.addTextBox();
                      break;
                    case 'table':
                      controller.addTable();
                      break;
                    case 'clear':
                      controller.clearCanvas();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _menuItem('sticky', LucideIcons.stickyNote, 'Sticky Note'),
                  _menuItem('textbox', LucideIcons.type, 'Text Box'),
                  _menuItem('table', LucideIcons.table, 'Dynamic Table'),
                  const PopupMenuDivider(),
                  _menuItem('clear', LucideIcons.trash2, 'Clear Whiteboard'),
                ],
              ),

              const _VerticalDivider(),

              // Color Palette Picker
              ..._palette.map((c) => _ColorDot(
                    color: c,
                    isSelected: controller.currentColor == c,
                    onTap: () => controller.setColor(c),
                  )),

              const _VerticalDivider(),

              // Stroke Width Adjuster
              PopupMenuButton<double>(
                tooltip: 'Stroke Width',
                icon: Icon(
                  LucideIcons.circle,
                  size: 14 + controller.strokeWidth * 0.8,
                  color: controller.currentColor,
                ),
                color: const Color(0xFFF7F4EE),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2DCD0)),
                ),
                onSelected: (w) => controller.setStrokeWidth(w),
                itemBuilder: (context) => [
                  _widthMenuItem(1.5, 'Fine (1.5px)'),
                  _widthMenuItem(3.0, 'Medium (3.0px)'),
                  _widthMenuItem(6.0, 'Thick (6.0px)'),
                  _widthMenuItem(12.0, 'Marker (12.0px)'),
                ],
              ),

              const _VerticalDivider(),

              // Paper Style Selector
              PopupMenuButton<PaperStyle>(
                tooltip: 'Paper Style',
                icon: const Icon(LucideIcons.grid, size: 18, color: Color(0xFF4A4E57)),
                color: const Color(0xFFF7F4EE),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2DCD0)),
                ),
                onSelected: (style) => controller.setPaperStyle(style),
                itemBuilder: (context) => [
                  _paperMenuItem(PaperStyle.ivoryPlain, 'Warm Ivory Plain'),
                  _paperMenuItem(PaperStyle.engineeringGrid, 'Engineering Grid'),
                  _paperMenuItem(PaperStyle.dotGrid, 'Dot Matrix'),
                  _paperMenuItem(PaperStyle.darkChalkboard, 'Dark Chalkboard'),
                ],
              ),

              const _VerticalDivider(),

              // Undo Button
              _ToolButton(
                icon: LucideIcons.undo2,
                tooltip: 'Undo',
                isSelected: false,
                isEnabled: controller.canUndo,
                onPressed: controller.undo,
              ),

              // Redo Button
              _ToolButton(
                icon: LucideIcons.redo2,
                tooltip: 'Redo',
                isSelected: false,
                isEnabled: controller.canRedo,
                onPressed: controller.redo,
              ),

              const _VerticalDivider(),

              // Zoom Level Display & Reset Button
              InkWell(
                onTap: controller.resetZoom,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    '${(controller.zoomLevel * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4E57),
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

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF374151)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  PopupMenuItem<PaperStyle> _paperMenuItem(PaperStyle style, String label) {
    return PopupMenuItem<PaperStyle>(
      value: style,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: controller.paperStyle == style ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  PopupMenuItem<double> _widthMenuItem(double val, String label) {
    return PopupMenuItem<double>(
      value: val,
      child: Row(
        children: [
          Container(
            width: val.clamp(2.0, 16.0),
            height: val.clamp(2.0, 16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF2D3139),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool isEnabled;
  final Color? accentColor;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    this.isEnabled = true,
    this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSelected ? const Color(0xFF2D3139) : Colors.transparent;
    final iconColor = isSelected
        ? Colors.white
        : (accentColor ?? (isEnabled ? const Color(0xFF4A4E57) : const Color(0xFFB5AFA4)));

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF2D3139) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE2DCD0),
    );
  }
}
