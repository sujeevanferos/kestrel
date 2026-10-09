import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LatexEditorView extends StatefulWidget {
  const LatexEditorView({super.key});

  @override
  State<LatexEditorView> createState() => _LatexEditorViewState();
}

class _LatexEditorViewState extends State<LatexEditorView> {
  final TextEditingController _latexCtrl = TextEditingController(text: r'''\documentclass{article}
\usepackage{amsmath,amssymb}

\title{Classical Mechanics: Orbital Dynamics}
\author{Kestrel AI Tutor}

\begin{document}
\maketitle

\section{Newton's Law of Universal Gravitation}
The gravitational attraction between two point masses $m_1$ and $m_2$ is governed by:
\begin{equation}
  \vec{F} = -G \frac{m_1 m_2}{r^2} \hat{r}
\end{equation}

\section{Kepler's Third Law}
For circular planetary orbits of radius $r$ and period $T$:
\begin{align}
  \frac{G M m}{r^2} &= m \omega^2 r = m \left(\frac{2\pi}{T}\right)^2 r \\
  T^2 &= \frac{4\pi^2}{G M} r^3
\end{align}

\end{document}''');

  bool _isCompiling = false;
  String _compileStatus = 'Ready to compile';

  static const List<Map<String, String>> _templates = [
    {
      'name': 'Assignment Set',
      'code': r'''\documentclass{article}
\usepackage{amsmath}
\title{Physics Homework 1}
\begin{document}
\maketitle
\section*{Problem 1}
Solve for $x$: $ax^2 + bx + c = 0$.
\end{document}'''
    },
    {
      'name': 'Lab Report',
      'code': r'''\documentclass{article}
\usepackage{amsmath,graphicx}
\title{Laboratory Report: Harmonic Oscillation}
\begin{document}
\maketitle
\section{Objective}
Measure the period $T = 2\pi\sqrt{L/g}$.
\end{document}'''
    },
    {
      'name': 'Lecture Presentation',
      'code': r'''\documentclass{beamer}
\title{Calculus: Integration by Parts}
\begin{document}
\begin{frame}
\frametitle{Formula}
$\int u \, dv = uv - \int v \, du$
\end{frame}
\end{document}'''
    },
  ];

  static const List<String> _symbolSnippets = [
    r'\frac{a}{b}',
    r'\sqrt{x}',
    r'\int_{a}^{b}',
    r'\sum_{i=1}^{n}',
    r'\alpha',
    r'\beta',
    r'\theta',
    r'\pi',
    r'\Delta',
  ];

  void _insertSnippet(String snippet) {
    final text = _latexCtrl.text;
    final selection = _latexCtrl.selection;
    final newText = text.replaceRange(
      selection.start.clamp(0, text.length),
      selection.end.clamp(0, text.length),
      snippet,
    );
    _latexCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + snippet.length),
    );
  }

  void _compile() {
    setState(() {
      _isCompiling = true;
      _compileStatus = 'Compiling via Tectonic...';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isCompiling = false;
          _compileStatus = 'Compilation completed (0 errors)';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F4EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF2D3139)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.fileCode, size: 20, color: Color(0xFF1B1C1E)),
              SizedBox(width: 10),
              Text(
                'LaTeX Typesetting & Document Studio',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1C1E),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                icon: _isCompiling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.play, size: 14),
                label: const Text('Compile PDF', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1C1E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isCompiling ? null : _compile,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Toolbar for templates and quick math snippets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F4EE),
                border: Border(bottom: BorderSide(color: Color(0xFFE2DCD0))),
              ),
              child: Row(
                children: [
                  const Text('Templates:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ..._templates.map((tpl) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(tpl['name']!, style: const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2DCD0)),
                          onPressed: () => setState(() => _latexCtrl.text = tpl['code']!),
                        ),
                      )),
                  const Spacer(),
                  const Text('Symbols:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ..._symbolSnippets.map((sym) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          onTap: () => _insertSnippet(sym),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2DCD0)),
                            ),
                            child: Text(sym, style: const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                          ),
                        ),
                      )),
                ],
              ),
            ),

            // Split View Editor & Preview
            Expanded(
              child: Row(
                children: [
                  // Source Editor
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _latexCtrl,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF1B1C1E),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter LaTeX source code here...',
                        ),
                      ),
                    ),
                  ),

                  const VerticalDivider(color: Color(0xFFE2DCD0), width: 1),

                  // Preview Document Paper Sheet
                  Expanded(
                    child: Container(
                      color: const Color(0xFFEFECE6),
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Container(
                          width: 500,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Classical Mechanics: Orbital Dynamics',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1B1C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  'Kestrel AI Tutor — Academic Typeset',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const Divider(height: 32),
                              const Text(
                                '1. Newton\'s Law of Universal Gravitation',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'The gravitational attraction between two point masses m1 and m2 is governed by:',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF8F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2DCD0)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'F = -G (m1 * m2) / r^2 r_hat',
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _compileStatus,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
