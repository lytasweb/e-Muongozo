import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_service.dart';

final pdfBytesProvider =
    FutureProvider.family<List<int>, int>((ref, topicId) async {
  return PdfService.fetchPdfBytes(topicId);
});
