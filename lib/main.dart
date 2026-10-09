import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'canvas/canvas_controller.dart';
import 'canvas/whiteboard_canvas.dart';
import 'services/ai_service.dart';
import 'ui/drawer/app_drawer.dart';
import 'ui/toolbar/floating_toolbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService.instance.loadSettings();
  runApp(const KestrelApp());
}

class KestrelApp extends StatelessWidget {
  const KestrelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kestrel STEM Workstation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF8F2),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B1C1E),
          surface: Color(0xFFF7F4EE),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1B1C1E),
        ),
      ),
      home: const WhiteboardScreen(),
    );
  }
}

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CanvasController _controller = CanvasController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showNotice(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(LucideIcons.info, size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '$featureName module initialized.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        controller: _controller,
        onOpenGraphStudio: () => _showNotice('Graph Studio (Desmos 2D/3D)'),
        onOpenLatexEditor: () => _showNotice('LaTeX Document Typesetting'),
        onOpenKnowledgeGraph: () => _showNotice('Knowledge Graph (Obsidian-style)'),
        onOpenSimulations: () => _showNotice('STEM Simulations & Arcade'),
        onOpenVideoGenerator: () => _showNotice('LaTeX Pedagogical Video Generator'),
        onOpenCollab: () => _showNotice('LAN Live Whiteboard Collaboration'),
      ),
      body: Stack(
        children: [
          // 1. Full-screen Inking Canvas
          Positioned.fill(
            child: WhiteboardCanvas(controller: _controller),
          ),

          // 2. Minimalist Header Branding & Drawer Toggle (Top-Left)
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: InkWell(
                onTap: _openDrawer,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EE).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DCD0), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.menu, size: 18, color: Color(0xFF2D3139)),
                      SizedBox(width: 8),
                      Text(
                        'KESTREL',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Color(0xFF1B1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Bottom Inking Controls Capsule Toolbar
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SafeArea(
                child: FloatingToolbar(
                  controller: _controller,
                  onOpenMenu: _openDrawer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
