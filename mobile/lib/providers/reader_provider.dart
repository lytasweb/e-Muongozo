import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';

final readerBlocksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, topicId) async {
  return DbService.getBlocks(topicId);
});