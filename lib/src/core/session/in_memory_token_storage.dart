import 'token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  @override
  Future<void> clearAccessToken() async {
    _accessToken = null;
  }
}
