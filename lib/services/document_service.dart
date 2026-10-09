import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../canvas/models/canvas_item.dart';
import '../notebook/models/document_model.dart';
import 'ai_service.dart';

class DocumentService extends ChangeNotifier {
  static final DocumentService instance = DocumentService._internal();
  DocumentService._internal();

  static const String _storageKey = 'kestrel_documents_v1';
  final List<AcademicDocument> _documents = [];

  List<AcademicDocument> get documents => List.unmodifiable(_documents);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _documents.clear();
        for (final item in list) {
          _documents.add(AcademicDocument.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      } catch (_) {
        _populateDefaults();
      }
    } else {
      _populateDefaults();
      await _persist();
    }
    notifyListeners();
  }

  void _populateDefaults() {
    _documents.clear();
    _documents.addAll([
      AcademicDocument(
        id: 'doc_euler_lagrange',
        title: 'Derivation of Euler-Lagrange Equations in Phase Space',
        pdfPath: 'sample_euler_lagrange.pdf',
        pageCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        summary: 'Analytical mechanics formulation through Hamilton\'s principle of least action.',
        latexSource: r'''\documentclass{article}
\usepackage{amsmath,amssymb}
\title{Euler-Lagrange Equations in Generalized Coordinates}
\author{Kestrel STEM Workstation}
\date{\today}
\begin{document}
\maketitle
\begin{abstract}
We derive the Euler-Lagrange equations governing dynamical trajectories from the stationary action principle $\delta S = 0$.
\end{abstract}
\section{Action Functional}
Let the action functional be defined as:
\begin{equation}
S[q] = \int_{t_1}^{t_2} L(q(t), \dot{q}(t), t) \, dt
\end{equation}
Taking the functional variation $\delta S = 0$ yields:
\begin{equation}
\frac{d}{dt}\left(\frac{\partial L}{\partial \dot{q}_i}\right) - \frac{\partial L}{\partial q_i} = 0
\end{equation}
\end{document}''',
      ),
      AcademicDocument(
        id: 'doc_maxwell',
        title: 'Maxwell\'s Equations and the Vector Wave Equation',
        pdfPath: 'sample_maxwell.pdf',
        pageCount: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        summary: 'Derivation of electromagnetic wave propagation in vacuum from curl equations.',
        latexSource: r'''\documentclass{article}
\usepackage{amsmath,amssymb}
\title{Electromagnetic Wave Equation}
\begin{document}
\section{Differential Field Equations}
\begin{align}
\nabla \cdot \mathbf{E} &= \frac{\rho}{\varepsilon_0} \\
\nabla \cdot \mathbf{B} &= 0 \\
\nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \\
\nabla \times \mathbf{B} &= \mu_0 \mathbf{J} + \mu_0 \varepsilon_0 \frac{\partial \mathbf{E}}{\partial t}
\end{align}
\end{document}''',
      ),
    ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_documents.map((d) => d.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  Future<void> addDocument(AcademicDocument doc) async {
    _documents.insert(0, doc);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
    await _persist();
    notifyListeners();
  }

  /// Synthesizes an academic document from selected whiteboard items
  Future<AcademicDocument> generateFromSelection({
    required List<CanvasItem> items,
    String? customTopic,
  }) async {
    final textContents = <String>[];
    for (final it in items) {
      if (it is StickyNoteItem) {
        textContents.add(it.text);
      } else if (it is TextBoxItem) {
        textContents.add(it.text);
      } else if (it is TableItem) {
        textContents.add('Table data: ${it.cells.values.join(", ")}');
      }
    }

    final topic = customTopic ??
        (textContents.isNotEmpty
            ? textContents.join(' ')
            : 'Analytical Derivation & Mathematical Notes');

    final latex = await AIService.instance.generateLessonLatex(
      'Create a formal academic article document for: $topic',
    );

    final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final newDoc = AcademicDocument(
      id: docId,
      title: customTopic ?? (textContents.isNotEmpty ? textContents.first : 'Academic Whiteboard Derivation'),
      pdfPath: '$docId.pdf',
      pageCount: 2,
      createdAt: DateTime.now(),
      summary: 'Generated from ${items.length} selected whiteboard elements.',
      latexSource: latex,
    );

    await addDocument(newDoc);
    return newDoc;
  }
}
