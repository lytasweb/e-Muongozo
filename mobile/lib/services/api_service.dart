import 'package:dio/dio.dart';
import '../config/api.dart';
import '../models/subject.dart';
import '../models/term.dart';
import '../models/topic.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.endpoint(''),
            connectTimeout: ApiConfig.timeout,
            receiveTimeout: ApiConfig.timeout,
          ),
        );

  Future<List<Subject>> getSubjects() async {
    final res = await _dio.get('/mobile/subjects');
    return (res.data['subjects'] as List)
        .map((j) => Subject.fromJson(j))
        .toList();
  }

  Future<List<Term>> getTerms(int subjectId) async {
    final res = await _dio.get('/mobile/subjects/$subjectId/terms');
    return (res.data['terms'] as List)
        .map((j) => Term.fromJson(j))
        .toList();
  }

  Future<List<Topic>> getTermBundle(int subjectId, int term) async {
    final res = await _dio.get('/mobile/terms/$subjectId/$term');
    return (res.data['topics'] as List)
        .map((j) => Topic.fromJson(j))
        .toList();
  }
}
