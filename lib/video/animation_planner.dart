import 'dart:math' as math;
import 'models/lesson_document.dart';

class TimelineState {
  final int stateIndex;
  final String sceneId;
  final String title;
  final List<DocumentElement> visibleElements;
  final DocumentElement? newlyRevealedElement;
  final int holdDurationMs;

  const TimelineState({
    required this.stateIndex,
    required this.sceneId,
    required this.title,
    required this.visibleElements,
    this.newlyRevealedElement,
    this.holdDurationMs = 3000,
  });
}

class AnimationPlanner {
  /// Parses educational LaTeX code into a structured LessonDocument IR
  static LessonDocument parseLatex(String latex, {String fallbackTitle = 'Lesson'}) {
    final titleMatch = RegExp(r'\\title\{([^}]+)\}').firstMatch(latex);
    final title = titleMatch?.group(1)?.trim() ?? fallbackTitle;

    final scenes = <SlideScene>[];

    // Split by \section or \begin{frame}
    final sectionMatches = RegExp(r'\\section\{([^}]+)\}([\s\S]*?)(?=\\section\{|\\end\{document\}|$)').allMatches(latex);

    if (sectionMatches.isEmpty) {
      // Single scene fallback
      final elements = _extractElements(latex);
      scenes.add(SlideScene(id: 'scene_0', title: title, elements: elements));
    } else {
      var idx = 0;
      for (final m in sectionMatches) {
        final secTitle = m.group(1)?.trim() ?? 'Section';
        final body = m.group(2) ?? '';
        final elements = _extractElements(body);
        scenes.add(SlideScene(id: 'scene_$idx', title: secTitle, elements: elements));
        idx++;
      }
    }

    return LessonDocument(title: title, scenes: scenes);
  }

  static List<DocumentElement> _extractElements(String body) {
    final elements = <DocumentElement>[];
    var elemId = 0;

    // Extract equations: \[ ... \] or \begin{equation} ... \end{equation}
    final equationRegex = RegExp(r'(\\\[[\s\S]*?\\\]|\\begin\{equation\*?\}[\s\S]*?\\end\{equation\*?\}|\\begin\{align\*?\}[\s\S]*?\\end\{align\*?\})');

    final chunks = body.split('\n\n');
    for (final chunk in chunks) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;

      if (equationRegex.hasMatch(trimmed)) {
        elements.add(DocumentElement(
          id: 'elem_${elemId++}',
          type: ElementType.equation,
          content: trimmed,
          transition: TransitionType.alphaReveal,
          holdDurationSec: 4.0,
        ));
      } else if (trimmed.startsWith(r'\begin{itemize}') || trimmed.startsWith(r'\begin{enumerate}')) {
        elements.add(DocumentElement(
          id: 'elem_${elemId++}',
          type: ElementType.bulletList,
          content: trimmed,
          transition: TransitionType.slideUp,
          holdDurationSec: 3.5,
        ));
      } else {
        // Plain text explanation paragraph
        final cleanText = trimmed.replaceAll(RegExp(r'\\[a-zA-Z]+(\[[^\]]*\])?(\{([^}]*)\})?'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleanText.length > 5) {
          elements.add(DocumentElement(
            id: 'elem_${elemId++}',
            type: ElementType.text,
            content: trimmed,
            transition: TransitionType.alphaReveal,
            holdDurationSec: math.max(2.5, cleanText.length * 0.05),
          ));
        }
      }
    }

    return elements;
  }

  /// Plans the progressive reveal timeline for each scene
  static List<TimelineState> planTimeline(LessonDocument doc) {
    final timeline = <TimelineState>[];
    var stateCounter = 0;

    for (final scene in doc.scenes) {
      final accumulated = <DocumentElement>[];

      // Initial state: slide title card
      timeline.add(TimelineState(
        stateIndex: stateCounter++,
        sceneId: scene.id,
        title: scene.title,
        visibleElements: const [],
        holdDurationMs: 2500,
      ));

      // Progressive reveal states
      for (final elem in scene.elements) {
        accumulated.add(elem);
        final holdMs = (elem.holdDurationSec * 1000).toInt();

        timeline.add(TimelineState(
          stateIndex: stateCounter++,
          sceneId: scene.id,
          title: scene.title,
          visibleElements: List.of(accumulated),
          newlyRevealedElement: elem,
          holdDurationMs: holdMs,
        ));
      }
    }

    return timeline;
  }

  /// Generates presentation LaTeX source for a multi-page PDF compilation
  static String generatePresentationLatex(List<TimelineState> timeline) {
    final sb = StringBuffer();
    sb.writeln(r'\documentclass[12pt]{article}');
    sb.writeln(r'\usepackage[margin=1.5in]{geometry}');
    sb.writeln(r'\usepackage{amsmath,amssymb,amsfonts}');
    sb.writeln(r'\usepackage{xcolor}');
    sb.writeln(r'\usepackage{tcolorbox}');
    sb.writeln(r'\pagestyle{empty}');
    sb.writeln(r'\begin{document}');

    for (var i = 0; i < timeline.length; ++i) {
      final state = timeline[i];
      sb.writeln(r'\begin{center}');
      sb.writeln('{\\LARGE\\bfseries ${state.title}}\\\\');
      sb.writeln(r'\vspace{0.8cm}');
      sb.writeln(r'\end{center}');

      for (final elem in state.visibleElements) {
        final isNew = elem.id == state.newlyRevealedElement?.id;
        if (isNew && elem.type == ElementType.equation) {
          sb.writeln(r'\begin{tcolorbox}[colback=blue!5!white,colframe=blue!75!black,arc=4mm]');
          sb.writeln(elem.content);
          sb.writeln(r'\end{tcolorbox}');
        } else {
          sb.writeln(elem.content);
        }
        sb.writeln(r'\vspace{0.4cm}');
      }

      if (i < timeline.length - 1) {
        sb.writeln(r'\newpage');
      }
    }

    sb.writeln(r'\end{document}');
    return sb.toString();
  }
}
