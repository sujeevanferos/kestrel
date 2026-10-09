import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/notebook_models.dart';

class NotebookService extends ChangeNotifier {
  static final NotebookService instance = NotebookService._internal();
  NotebookService._internal();

  static const String _storageKey = 'kestrel_notebooks_v1';

  final List<Subject> _subjects = [];
  String? _activeSubjectId;
  String? _activePageId;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  String? get activeSubjectId => _activeSubjectId;
  String? get activePageId => _activePageId;

  NotebookPage? get activePage {
    if (_activeSubjectId == null || _activePageId == null) return null;
    final subj = _subjects.firstWhere((s) => s.id == _activeSubjectId, orElse: () => _subjects.first);
    return subj.pages.firstWhere((p) => p.id == _activePageId, orElse: () => subj.pages.first);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final list = jsonDecode(rawJson) as List<dynamic>;
        _subjects.clear();
        for (final item in list) {
          _subjects.add(Subject.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      } catch (_) {
        _populateDefaultCurriculum();
      }
    } else {
      _populateDefaultCurriculum();
      await _persist();
    }

    if (_subjects.isNotEmpty) {
      _activeSubjectId = _subjects.first.id;
      if (_subjects.first.pages.isNotEmpty) {
        _activePageId = _subjects.first.pages.first.id;
      }
    }
    notifyListeners();
  }

  void _populateDefaultCurriculum() {
    _subjects.clear();
    _subjects.addAll([
      Subject(
        id: 'subj_physics',
        name: 'Classical Mechanics & Astrophysics',
        colorValue: 0xFF1E3A8A, // Fountain Blue
        pages: [
          NotebookPage(
            id: 'page_kepler',
            title: 'Kepler\'s Laws & Gravitational Potential',
            updatedAt: DateTime.now(),
          ),
          NotebookPage(
            id: 'page_lagrangian',
            title: 'Lagrangian & Hamiltonian Dynamics',
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      Subject(
        id: 'subj_calculus',
        name: 'Multivariable & Vector Calculus',
        colorValue: 0xFF2D6A4F, // Sage Green
        pages: [
          NotebookPage(
            id: 'page_stokes',
            title: 'Stokes\' & Divergence Theorems',
            updatedAt: DateTime.now(),
          ),
          NotebookPage(
            id: 'page_fourier',
            title: 'Fourier Series & Boundary Values',
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      Subject(
        id: 'subj_electromagnetism',
        name: 'Electromagnetism & Waves',
        colorValue: 0xFFB91C1C, // Crimson Note
        pages: [
          NotebookPage(
            id: 'page_maxwell',
            title: 'Maxwell\'s Equations in Differential Form',
            updatedAt: DateTime.now(),
          ),
        ],
      ),
    ]);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_subjects.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  void setActivePage(String subjectId, String pageId) {
    _activeSubjectId = subjectId;
    _activePageId = pageId;
    notifyListeners();
  }

  Future<void> addSubject(String name, int colorValue) async {
    final newSubj = Subject(
      id: 'subj_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: colorValue,
      pages: [
        NotebookPage(
          id: 'page_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Blank Board 1',
          updatedAt: DateTime.now(),
        ),
      ],
    );
    _subjects.add(newSubj);
    _activeSubjectId = newSubj.id;
    _activePageId = newSubj.pages.first.id;
    await _persist();
    notifyListeners();
  }

  Future<void> addPageToSubject(String subjectId, String title) async {
    for (final s in _subjects) {
      if (s.id == subjectId) {
        final newPage = NotebookPage(
          id: 'page_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          updatedAt: DateTime.now(),
        );
        s.pages.add(newPage);
        _activePageId = newPage.id;
        _activeSubjectId = subjectId;
        await _persist();
        notifyListeners();
        return;
      }
    }
  }

  Future<void> savePageContent(String subjectId, String pageId, List<Map<String, dynamic>> itemsJson) async {
    for (final s in _subjects) {
      if (s.id == subjectId) {
        for (final p in s.pages) {
          if (p.id == pageId) {
            p.itemsJson = itemsJson;
            p.updatedAt = DateTime.now();
            await _persist();
            return;
          }
        }
      }
    }
  }

  Future<void> deletePage(String subjectId, String pageId) async {
    for (final s in _subjects) {
      if (s.id == subjectId) {
        s.pages.removeWhere((p) => p.id == pageId);
        if (_activePageId == pageId && s.pages.isNotEmpty) {
          _activePageId = s.pages.first.id;
        }
        await _persist();
        notifyListeners();
        return;
      }
    }
  }
}
