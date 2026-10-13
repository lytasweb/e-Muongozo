class Term {
  final int subjectId;
  final int term;
  final int topicCount;
  final int sizeBytes;

  const Term({
    required this.subjectId,
    required this.term,
    required this.topicCount,
    required this.sizeBytes,
  });

  factory Term.fromJson(Map<String, dynamic> json) => Term(
        subjectId: json['subject_id'],
        term: json['term'],
        topicCount: json['topic_count'],
        sizeBytes: json['size_bytes'] ?? 0,
      );

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
