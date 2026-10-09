import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'canvas/canvas_controller.dart';
import 'canvas/whiteboard_canvas.dart';
import 'notebook/notebook_service.dart';
import 'services/ai_service.dart';
import 'ui/ai_tutor/math_solver_dialog.dart';
import 'ui/ai_tutor/socratic_tutor_dialog.dart';
import 'ui/collab/collab_dialog.dart';
import 'ui/drawer/app_drawer.dart';
import 'ui/graph_studio/graph_studio_view.dart';
import 'ui/knowledge_graph/knowledge_graph_view.dart';
import 'ui/latex/latex_editor_view.dart';
import 'ui/notebook/notebook_manager_dialog.dart';
import 'ui/toolbar/floating_toolbar.dart';
import 'ui/video/video_generator_dialog.dart';
import 'ui/widgets/stem_utilities_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService.instance.loadSettings();
  await NotebookService.instance.init();
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
  late final CanvasController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = CanvasController();

    // Load active page from NotebookService if available
    final activePage = NotebookService.instance.activePage;
    if (activePage != null && activePage.itemsJson.isNotEmpty) {
      _controller.importBoardJson(activePage.itemsJson);
    }
  }

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
        onOpenNotebooks: () {
          showDialog(
            context: context,
            builder: (_) => NotebookManagerDialog(canvasController: _controller),
          );
        },
        onOpenKnowledgeGraph: () {
          showDialog(
            context: context,
            builder: (_) => const KnowledgeGraphView(),
          );
        },
        onOpenSocraticTutor: () {
          showDialog(
            context: context,
            builder: (_) => SocraticTutorDialog(
              onInsertToBoard: (hint) => _controller.addStickyNote(text: hint),
            ),
          );
        },
        onOpenMathSolver: () {
          showDialog(
            context: context,
            builder: (_) => MathSolverDialog(
              onInsertToBoard: (derivation) => _controller.addTextBox(text: derivation),
            ),
          );
        },
        onOpenGraphStudio: () {
          showDialog(
            context: context,
            builder: (_) => GraphStudioView(
              onEmbedToCanvas: (formula) {
                _controller.addTextBox(text: 'y = $formula');
                _showNotice('Embedded graph formula to canvas');
              },
            ),
          );
        },
        onOpenLatexEditor: () {
          showDialog(
            context: context,
            builder: (_) => const LatexEditorView(),
          );
        },
        onOpenSimulations: () {
          showDialog(
            context: context,
            builder: (_) => const StemUtilitiesDialog(),
          );
        },
        onOpenVideoGenerator: () {
          showDialog(
            context: context,
            builder: (_) => VideoGeneratorDialog(
              onMountToWhiteboard: (videoPath, title) {
                _controller.addVideoPlayer(videoPath: videoPath, title: title);
                _showNotice('Lesson video mounted to whiteboard');
              },
            ),
          );
        },
        onOpenCollab: () {
          showDialog(
            context: context,
            builder: (_) => const CollabDialog(),
          );
        },
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
              child: Row(
                children: [
                  InkWell(
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
                  const SizedBox(width: 8),
                  // Quick Socratic AI Summoner Button
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => SocraticTutorDialog(
                          onInsertToBoard: (hint) => _controller.addStickyNote(text: hint),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          Icon(LucideIcons.sparkles, size: 15, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text(
                            'Ask AI',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Bottom Toolbar
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
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
