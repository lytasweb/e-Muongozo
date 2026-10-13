import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/db_service.dart';

final continueReadingProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DbService.getRecentlyRead(limit: 5);
});