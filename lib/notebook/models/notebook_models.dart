class NotebookPage {
  final String id;
  String title;
  DateTime updatedAt;
  List<Map<String, dynamic>> itemsJson;

  NotebookPage({
    required this.id,
    required this.title,
    required this.updatedAt,
    List<Map<String, dynamic>>? itemsJson,
  }) : itemsJson = itemsJson ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
    'itemsJson': itemsJson,
  };

  factory NotebookPage.fromJson(Map<String, dynamic> json) => NotebookPage(
    id: json['id'] as String,
    title: json['title'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    itemsJson: (json['itemsJson'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [],
  );
}

class Subject {
  final String id;
  String name;
  int colorValue;
  List<NotebookPage> pages;

  Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    List<NotebookPage>? pages,
  }) : pages = pages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'pages': pages.map((p) => p.toJson()).toList(),
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    colorValue: json['colorValue'] as int? ?? 0xFF1E3A8A,
    pages: (json['pages'] as List<dynamic>?)
            ?.map((p) => NotebookPage.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList() ??
        [],
  );
}

/// Node in the Obsidian-Style Knowledge Graph
class KnowledgeNode {
  final String id;
  final String label;
  final String category; // 'Subject', 'Theorem', 'Formula', 'Board'
  final int colorValue;
  double x;
  double y;
  double vx;
  double vy;

  KnowledgeNode({
    required this.id,
    required this.label,
    required this.category,
    required this.colorValue,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
  });
}

/// Directed link between knowledge nodes
class KnowledgeEdge {
  final String sourceId;
  final String targetId;
  final String label;

  KnowledgeEdge({
    required this.sourceId,
    required this.targetId,
    this.label = '',
  });
}
