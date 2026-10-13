import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../services/api_service.dart';

final termsProvider =
    FutureProvider.family<List<Term>, int>((ref, subjectId) async {
  return ApiService().getTerms(subjectId);
});
