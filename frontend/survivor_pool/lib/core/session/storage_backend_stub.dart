class AuthStorageBackend {
  Future<void> write(String key, String value) async {
    throw UnimplementedError('Storage backend not configured');
  }

  Future<String?> read(String key) async {
    throw UnimplementedError('Storage backend not configured');
  }

  Future<void> delete(String key) async {
    throw UnimplementedError('Storage backend not configured');
  }
}
