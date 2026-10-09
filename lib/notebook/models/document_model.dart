class AcademicDocument {
  final String id;
  final String title;
  final String pdfPath;
  final int pageCount;
  final DateTime createdAt;
  final String latexSource;
  final String summary;

  AcademicDocument({
    required this.id,
    required this.title,
    required this.pdfPath,
    this.pageCount = 1,
    required this.createdAt,
    this.latexSource = '',
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'pdfPath': pdfPath,
    'pageCount': pageCount,
    'createdAt': createdAt.toIso8601String(),
    'latexSource': latexSource,
    'summary': summary,
  };

  factory AcademicDocument.fromJson(Map<String, dynamic> json) => AcademicDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    pdfPath: json['pdfPath'] as String? ?? '',
    pageCount: (json['pageCount'] as int?) ?? 1,
    createdAt: DateTime.parse(json['createdAt'] as String),
    latexSource: json['latexSource'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
  );
}
