enum ElementType {
  title,
  section,
  equation,
  text,
  bulletList,
  boxHighlight,
}

enum TransitionType {
  alphaReveal,
  slideUp,
  highlight,
  none,
}

class DocumentElement {
  final String id;
  final ElementType type;
  final String content;
  final TransitionType transition;
  final double holdDurationSec;

  const DocumentElement({
    required this.id,
    required this.type,
    required this.content,
    this.transition = TransitionType.alphaReveal,
    this.holdDurationSec = 3.0,
  });
}

class SlideScene {
  final String id;
  final String title;
  final List<DocumentElement> elements;

  const SlideScene({
    required this.id,
    required this.title,
    required this.elements,
  });
}

class LessonDocument {
  final String title;
  final List<SlideScene> scenes;

  const LessonDocument({
    required this.title,
    required this.scenes,
  });
}
