import 'package:dio/dio.dart';
import '../config/api.dart';

class PdfService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.endpoint(''),
    connectTimeout: ApiConfig.timeout,
    receiveTimeout: ApiConfig.timeout,
  ));

  /// Downloads the PDF for a topic and returns the raw bytes.
  /// Throws on HTTP error.
  static Future<List<int>> fetchPdfBytes(int topicId) async {
    final res = await _dio.get<List<int>>(
      '/mobile/topics/$topicId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = res.data;
    if (data == null || data.isEmpty) {
      throw Exception('Empty PDF response');
    }
    return data;
  }
}
