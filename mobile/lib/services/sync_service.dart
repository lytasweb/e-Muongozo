import 'api_service.dart';
import 'db_service.dart';

class SyncService {
  final ApiService _api = ApiService();

  Future<void> syncSubjects() async {
    final subjects = await _api.getSubjects();
    await DbService.saveSubjects(subjects);
  }

  Future<int> syncTerm(int subjectId, int term) async {
    final topics = await _api.getTermBundle(subjectId, term);
    await DbService.saveTopics(topics);
    return topics.length;
  }
}
