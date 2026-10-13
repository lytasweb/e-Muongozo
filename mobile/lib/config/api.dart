class ApiConfig {
  // Change this to your backend IP
  static const String baseUrl = 'http://172.17.16.68:4000';
  static const String apiPrefix = '/api';

  static String endpoint(String path) => '$baseUrl$apiPrefix$path';

  static const Duration timeout = Duration(seconds: 30);
}
