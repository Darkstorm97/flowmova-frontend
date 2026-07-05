abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> saveAccessToken(String accessToken);

  Future<void> clearAccessToken();
}
