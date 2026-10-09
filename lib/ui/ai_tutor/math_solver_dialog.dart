import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/ai_service.dart';

class MathSolverDialog extends StatefulWidget {
  final void Function(String derivation)? onInsertToBoard;

  const MathSolverDialog({super.key, this.onInsertToBoard});

  @override
  State<MathSolverDialog> createState() => _MathSolverDialogState();
}

class _MathSolverDialogState extends State<MathSolverDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _solvePromptCtrl = TextEditingController();
  final TextEditingController _problemCtrl = TextEditingController();
  final TextEditingController _studentStepsCtrl = TextEditingController();

  bool _isLoading = false;
  String? _solutionResult;
  String? _verificationResult;
  String? _errorMessage;

  static const List<String> _solvePresets = [
    r'\int x^2 e^{3x} \, dx',
    r'\frac{d}{dx} \left( \frac{\ln(x)}{x^2 + 1} \right)',
    r'\lim_{x \to 0} \frac{\sin(5x) - 5x}{x^3}',
    r'\nabla \times (\mathbf{r} \times \mathbf{v})',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _solvePromptCtrl.dispose();
    _problemCtrl.dispose();
    _studentStepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSolver() async {
    final query = _solvePromptCtrl.text.trim();
    if (query.isEmpty) return;

    if (!AIService.instance.hasValidKey) {
      setState(() {
        _errorMessage = 'Please configure your Gemini or Grok API key in Settings.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _solutionResult = null;
    });

    try {
      final res = await AIService.instance.solveMathProblem(problemOrFormula: query);
      if (mounted) {
        setState(() {
          _solutionResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runVerifier() async {
    final prob = _problemCtrl.text.trim();
    final steps = _studentStepsCtrl.text.trim();
    if (prob.isEmpty || steps.isEmpty) return;

    if (!AIService.instance.hasValidKey) {
      setState(() {
        _errorMessage = 'Please configure your Gemini or Grok API key in Settings.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationResult = null;
    });

    try {
      final res = await AIService.instance.verifyMathWork(problem: prob, studentSteps: steps);
      if (mounted) {
        setState(() {
          _verificationResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 680,
        height: 720,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.binary, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'STEM Math Solver & Work Corrector',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1C1E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAE1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF1B1C1E),
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Step-by-Step Derivation'),
                  Tab(text: 'Work Error Corrector'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Derivation
                  _buildDerivationTab(),
                  // Tab 2: Error Corrector
                  _buildCorrectorTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mathematical Equation / Problem',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4E57)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _solvePromptCtrl,
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: r'e.g. \int x^2 \cos(x) dx',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2DCD0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2DCD0)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: _solvePresets.map((p) {
            return ActionChip(
              label: Text(p, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2DCD0)),
              onPressed: () => _solvePromptCtrl.text = p,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runSolver,
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.play, size: 14),
          label: Text(_isLoading ? 'Deriving Solution...' : 'Compute Derivation', style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B1C1E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2DCD0)),
            ),
            child: _solutionResult != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Step-by-Step Mathematical Derivation',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (widget.onInsertToBoard != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                widget.onInsertToBoard!(_solutionResult!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Derivation mounted to whiteboard')),
                                );
                              },
                              icon: const Icon(LucideIcons.layoutGrid, size: 12),
                              label: const Text('Mount to Board', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D6A4F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                      const Divider(color: Color(0xFFE2DCD0), height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _solutionResult!,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      _errorMessage ?? 'Enter an equation above to compute step-by-step working.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _errorMessage != null ? const Color(0xFFB91C1C) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectorTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Problem Statement',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4E57)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _problemCtrl,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'e.g. Find the roots of 2x^2 - 4x - 6 = 0',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Student Step-by-Step Working',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4E57)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _studentStepsCtrl,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Step 1: x^2 - 2x - 3 = 0\nStep 2: (x - 3)(x + 1) = 0\nStep 3: x = 3 or x = -1',
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _runVerifier,
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.checkCheck, size: 14),
          label: Text(_isLoading ? 'Verifying...' : 'Check & Verify Steps', style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2DCD0)),
            ),
            child: _verificationResult != null
                ? SingleChildScrollView(
                    child: SelectableText(
                      _verificationResult!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, height: 1.5, color: Color(0xFF1F2937)),
                    ),
                  )
                : Center(
                    child: Text(
                      _errorMessage ?? 'Submit student working above to detect algebra or conceptual errors.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _errorMessage != null ? const Color(0xFFB91C1C) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
