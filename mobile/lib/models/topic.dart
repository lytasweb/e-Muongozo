import 'content_block.dart';

class Topic {
  final int id;
  final int subjectId;
  final int term;
  final String title;
  final String badge;
  final List<ContentBlock> blocks;
  final List<String> teachingSchemes;
  final List<String> recommendedBooks;

  const Topic({
    required this.id,
    required this.subjectId,
    required this.term,
    required this.title,
    required this.badge,
    required this.blocks,
    this.teachingSchemes = const [],
    this.recommendedBooks = const [],
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'],
        subjectId: json['subject_id'],
        term: json['term'],
        title: json['title'],
        badge: json['badge'] ?? 'TIE-Official',
        blocks: (json['blocks'] as List? ?? [])
            .map((b) => ContentBlock.fromJson(b))
            .toList(),
        teachingSchemes: List<String>.from(json['teaching_schemes'] ?? []),
        recommendedBooks: List<String>.from(json['recommended_books'] ?? []),
      );
}
