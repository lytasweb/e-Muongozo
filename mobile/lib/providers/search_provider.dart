import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';

/// Family key = search query string.
final searchProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, q) async {
  return DbService.searchTopics(q);
});
