import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../canvas/models/canvas_item.dart';

class VideoFloatCard extends StatefulWidget {
  final VideoFloatItem item;
  final CanvasController controller;

  const VideoFloatCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<VideoFloatCard> createState() => _VideoFloatCardState();
}

class _VideoFloatCardState extends State<VideoFloatCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addListener(() {
        if (mounted) {
          setState(() {
            widget.item.progress = _animController.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      widget.item.isPlaying = !widget.item.isPlaying;
      if (widget.item.isPlaying) {
        if (_animController.isCompleted) _animController.reset();
        _animController.forward();
      } else {
        _animController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoom = widget.controller.zoomLevel;
    final isSelected = widget.controller.selectedItemId == widget.item.id;

    return Container(
      width: widget.item.width * zoom,
      height: widget.item.height * zoom,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate player
        borderRadius: BorderRadius.circular(10 * zoom),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12 * zoom,
            offset: Offset(2 * zoom, 6 * zoom),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          GestureDetector(
            onPanDown: (_) => widget.controller.selectItem(widget.item.id),
            onPanUpdate: (details) {
              final newX = widget.item.x + details.delta.dx / zoom;
              final newY = widget.item.y + details.delta.dy / zoom;
              widget.controller.updateItemPosition(widget.item.id, Offset(newX, newY));
            },
            child: Container(
              height: 32 * zoom,
              padding: EdgeInsets.symmetric(horizontal: 10 * zoom),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(9 * zoom)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.video, size: 14 * zoom, color: const Color(0xFF94A3B8)),
                  SizedBox(width: 8 * zoom),
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12 * zoom,
                        color: const Color(0xFFF8FAFC),
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.controller.deleteItem(widget.item.id),
                    child: Icon(LucideIcons.x, size: 14 * zoom, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
          // Screen / Presentation Canvas Area
          Expanded(
            child: Container(
              color: const Color(0xFF020617),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Presentation Slide Simulation
                  Padding(
                    padding: EdgeInsets.all(16 * zoom),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.presentation, size: 36 * zoom, color: const Color(0xFF64748B)),
                        SizedBox(height: 8 * zoom),
                        Text(
                          'Pedagogical Lesson Video',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14 * zoom,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4 * zoom),
                        Text(
                          widget.item.videoPath,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10 * zoom,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Big Play Button Overlay
                  if (!widget.item.isPlaying)
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: EdgeInsets.all(12 * zoom),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.play, size: 28 * zoom, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bottom Playback Controls
          Container(
            height: 38 * zoom,
            padding: EdgeInsets.symmetric(horizontal: 10 * zoom),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Icon(
                    widget.item.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    size: 16 * zoom,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8 * zoom),
                // Timeline progress bar
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5 * zoom),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 10 * zoom),
                      trackHeight: 3 * zoom,
                      activeTrackColor: const Color(0xFF6366F1),
                      inactiveTrackColor: const Color(0xFF334155),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: widget.item.progress.clamp(0.0, 1.0),
                      onChanged: (val) {
                        setState(() {
                          widget.item.progress = val;
                          _animController.value = val;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 6 * zoom),
                Text(
                  '${(widget.item.progress * 15).toInt()}s / 15s',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10 * zoom,
                    color: const Color(0xFF94A3B8),
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
