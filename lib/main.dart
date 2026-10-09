import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'canvas/canvas_controller.dart';
import 'canvas/whiteboard_canvas.dart';
import 'notebook/notebook_service.dart';
import 'services/ai_service.dart';
import 'services/document_service.dart';
import 'ui/ai_tutor/math_solver_dialog.dart';
import 'ui/ai_tutor/socratic_tutor_dialog.dart';
import 'ui/collab/collab_dialog.dart';
import 'ui/documents/documents_library_dialog.dart';
import 'ui/drawer/app_drawer.dart';
import 'ui/graph_studio/graph_studio_view.dart';
import 'ui/knowledge_graph/knowledge_graph_view.dart';
import 'ui/notebook/notebook_manager_dialog.dart';
import 'ui/toolbar/floating_toolbar.dart';
import 'ui/video/video_generator_dialog.dart';
import 'ui/widgets/stem_utilities_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AIService.instance.loadSettings();
  await NotebookService.instance.init();
  await DocumentService.instance.init();
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
  bool _isGeneratingDoc = false;

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

  void _showNotice(String message, {VoidCallback? onAction, String actionLabel = 'View'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
        ),
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: const Color(0xFF60A5FA),
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  Future<void> _handleGeneratePdf([_]) async {
    final selectedItems = _controller.getSelectedItems();
    if (selectedItems.isEmpty) {
      _showNotice('No items on whiteboard to generate document from.');
      return;
    }

    if (!AIService.instance.hasValidKey) {
      _showNotice('Please configure your Gemini or Grok API key in Settings first.');
      return;
    }

    setState(() {
      _isGeneratingDoc = true;
    });

    _showNotice('Compiling academic LaTeX document from ${selectedItems.length} elements...');

    try {
      final doc = await DocumentService.instance.generateFromSelection(items: selectedItems);
      if (mounted) {
        setState(() {
          _isGeneratingDoc = false;
        });
        _showNotice(
          'Document "${doc.title}" generated and saved to Documents Library!',
          actionLabel: 'Open Library',
          onAction: () {
            showDialog(
              context: context,
              builder: (_) => DocumentsLibraryDialog(initialDocumentId: doc.id),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingDoc = false;
        });
        _showNotice('Generation error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _handleGenerateVideo([_]) {
    showDialog(
      context: context,
      builder: (_) => VideoGeneratorDialog(
        onMountToWhiteboard: (videoPath, title) {
          _controller.addVideoPlayer(videoPath: videoPath, title: title);
          _showNotice('Lesson video mounted to whiteboard');
        },
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
        onOpenDocuments: () {
          showDialog(
            context: context,
            builder: (_) => const DocumentsLibraryDialog(),
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
        onOpenSimulations: () {
          showDialog(
            context: context,
            builder: (_) => const StemUtilitiesDialog(),
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
          // 1. Full-screen Inking Canvas with Selection Actions
          Positioned.fill(
            child: WhiteboardCanvas(
              controller: _controller,
              onGeneratePdf: _handleGeneratePdf,
              onGenerateVideo: _handleGenerateVideo,
            ),
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

          // 3. Document Generation Loading Banner (Top-Right)
          if (_isGeneratingDoc)
            Positioned(
              top: 20,
              right: 20,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1C1E),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text(
                        'Compiling Academic PDF...',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Floating Bottom Toolbar with Selection, PDF, and Video Tools
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: FloatingToolbar(
                  controller: _controller,
                  onOpenMenu: _openDrawer,
                  onGeneratePdf: _handleGeneratePdf,
                  onGenerateVideo: _handleGenerateVideo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
