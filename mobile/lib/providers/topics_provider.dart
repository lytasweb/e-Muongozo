import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';

class TermKey {
  final int subjectId;
  final int term;
  const TermKey(this.subjectId, this.term);

  @override
  bool operator ==(Object other) =>
      other is TermKey &&
      other.subjectId == subjectId &&
      other.term == term;

  @override
  int get hashCode => subjectId.hashCode ^ term.hashCode;
}

final topicsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, TermKey>((ref, key) async {
  return DbService.getTopics(key.subjectId, key.term);
});
