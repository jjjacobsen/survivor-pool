class ApiConfig {
  static const _baseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrl.isEmpty) {
      throw StateError('Missing required environment variable: API_BASE_URL');
    }
    return _baseUrl;
  }
}
