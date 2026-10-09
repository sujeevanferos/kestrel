import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../services/ai_service.dart';
import '../settings/settings_dialog.dart';

class AppDrawer extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onOpenGraphStudio;
  final VoidCallback onOpenLatexEditor;
  final VoidCallback onOpenKnowledgeGraph;
  final VoidCallback onOpenSimulations;
  final VoidCallback onOpenVideoGenerator;
  final VoidCallback onOpenCollab;

  const AppDrawer({
    super.key,
    required this.controller,
    required this.onOpenGraphStudio,
    required this.onOpenLatexEditor,
    required this.onOpenKnowledgeGraph,
    required this.onOpenSimulations,
    required this.onOpenVideoGenerator,
    required this.onOpenCollab,
  });

  @override
  Widget build(BuildContext context) {
    final ai = AIService.instance;

    return Drawer(
      backgroundColor: const Color(0xFFF7F4EE), // Warm parchment
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1C1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.feather, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KESTREL',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF1B1C1E),
                        ),
                      ),
                      Text(
                        'AI: ${ai.currentProvider.name.toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _sectionHeader('WORKSPACE MODULES'),
                  _drawerItem(
                    icon: LucideIcons.lineChart,
                    title: 'Graph Studio (2D/3D Plotter)',
                    subtitle: 'Desmos-style formulas & parameter sliders',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenGraphStudio();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.fileCode,
                    title: 'LaTeX Document Typesetting',
                    subtitle: 'Live Tectonic preview & templates',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenLatexEditor();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.gitFork,
                    title: 'Knowledge Graph',
                    subtitle: 'Obsidian-style interconnected concepts',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenKnowledgeGraph();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.video,
                    title: 'Pedagogical Video Generator',
                    subtitle: 'LaTeX timeline & on-device MP4 rendering',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenVideoGenerator();
                    },
                  ),

                  const SizedBox(height: 12),
                  _sectionHeader('INTERACTIVE TOOLS & SIMULATIONS'),
                  _drawerItem(
                    icon: LucideIcons.cpu,
                    title: 'STEM Utilities & Physics',
                    subtitle: 'Planetary orbits, pendulum, calculator, clock',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSimulations();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.users,
                    title: 'LAN Live Collaboration',
                    subtitle: 'Multi-peer whiteboard sync via room code',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenCollab();
                    },
                  ),

                  const SizedBox(height: 12),
                  _sectionHeader('CANVAS PAPER STYLE'),
                  _paperStyleSelector(),
                ],
              ),
            ),

            const Divider(color: Color(0xFFE2DCD0), height: 1),

            // Bottom Settings & Clear Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _drawerItem(
                    icon: LucideIcons.settings,
                    title: 'Settings & API Keys',
                    subtitle: 'Gemini & Grok configurations',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.trash2,
                    title: 'Clear Whiteboard',
                    iconColor: const Color(0xFFDC2626),
                    textColor: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(context);
                      controller.clearCanvas();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color(0xFF8C867A),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF4A4E57)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF1B1C1E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _paperStyleSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SegmentedButton<PaperStyle>(
        segments: const [
          ButtonSegment(
            value: PaperStyle.ivoryPlain,
            label: Text('Plain', style: TextStyle(fontSize: 11)),
          ),
          ButtonSegment(
            value: PaperStyle.engineeringGrid,
            label: Text('Grid', style: TextStyle(fontSize: 11)),
          ),
          ButtonSegment(
            value: PaperStyle.dotGrid,
            label: Text('Dots', style: TextStyle(fontSize: 11)),
          ),
          ButtonSegment(
            value: PaperStyle.darkChalkboard,
            label: Text('Chalk', style: TextStyle(fontSize: 11)),
          ),
        ],
        selected: {controller.paperStyle},
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFFE2DCD0))),
        ),
        onSelectionChanged: (set) {
          if (set.isNotEmpty) controller.setPaperStyle(set.first);
        },
      ),
    );
  }
}
