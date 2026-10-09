import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../canvas/canvas_controller.dart';
import '../../services/ai_service.dart';
import '../settings/settings_dialog.dart';

class AppDrawer extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback onOpenNotebooks;
  final VoidCallback onOpenSocraticTutor;
  final VoidCallback onOpenMathSolver;
  final VoidCallback onOpenGraphStudio;
  final VoidCallback onOpenLatexEditor;
  final VoidCallback onOpenKnowledgeGraph;
  final VoidCallback onOpenSimulations;
  final VoidCallback onOpenVideoGenerator;
  final VoidCallback onOpenCollab;

  const AppDrawer({
    super.key,
    required this.controller,
    required this.onOpenNotebooks,
    required this.onOpenSocraticTutor,
    required this.onOpenMathSolver,
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
                  _sectionHeader('CURRICULUM & NOTEBOOKS'),
                  _drawerItem(
                    icon: LucideIcons.bookOpen,
                    title: 'Subjects & Notebooks',
                    subtitle: 'Manage curriculum boards & pages',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenNotebooks();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.gitFork,
                    title: 'Knowledge Graph',
                    subtitle: 'Obsidian-style concept network',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenKnowledgeGraph();
                    },
                  ),

                  const SizedBox(height: 10),
                  _sectionHeader('AI TUTORING & STEM ENGINES'),
                  _drawerItem(
                    icon: LucideIcons.sparkles,
                    title: 'Socratic AI Tutor',
                    subtitle: 'Guided hints without spoiling answers',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSocraticTutor();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.binary,
                    title: 'Math Solver & Corrector',
                    subtitle: 'Step-by-step calculus & error check',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenMathSolver();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.video,
                    title: 'LaTeX Video Generator',
                    subtitle: 'On-device pedagogical MP4 renderer',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenVideoGenerator();
                    },
                  ),

                  const SizedBox(height: 10),
                  _sectionHeader('STUDIOS & TOOLS'),
                  _drawerItem(
                    icon: LucideIcons.lineChart,
                    title: 'Graph Studio (2D/3D)',
                    subtitle: 'Desmos-style formulas & sliders',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenGraphStudio();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.fileCode,
                    title: 'LaTeX Document Typesetting',
                    subtitle: 'Split-view live article editor',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenLatexEditor();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.cpu,
                    title: 'STEM Utilities & Physics',
                    subtitle: 'Orbits, pendulum, calculator, clock',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSimulations();
                    },
                  ),
                  _drawerItem(
                    icon: LucideIcons.users,
                    title: 'LAN Live Collaboration',
                    subtitle: 'P2P whiteboard sync via room code',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenCollab();
                    },
                  ),

                  const SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF9CA3AF),
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
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _paperChip('Ivory Plain', PaperStyle.ivoryPlain),
          _paperChip('Engineering Grid', PaperStyle.engineeringGrid),
          _paperChip('Dot Grid', PaperStyle.dotGrid),
          _paperChip('Dark Chalk', PaperStyle.darkChalkboard),
        ],
      ),
    );
  }

  Widget _paperChip(String label, PaperStyle style) {
    final isSelected = controller.paperStyle == style;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF1B1C1E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4A4E57),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2DCD0)),
      onSelected: (_) => controller.setPaperStyle(style),
    );
  }
}
