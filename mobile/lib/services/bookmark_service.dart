import 'db_service.dart';

class BookmarkService {
  static Future<void> toggle(int topicId) => DbService.toggleBookmark(topicId);
  static Future<List<int>> getAll() => DbService.getBookmarkIds();
}
