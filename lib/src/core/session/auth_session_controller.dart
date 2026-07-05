import 'package:flutter/foundation.dart';

import 'access_token.dart';
import 'in_memory_token_storage.dart';
import 'token_storage.dart';

enum AuthSessionStatus { unknown, unauthenticated, authenticated, expired }

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({required this.tokenStorage});

  AuthSessionController.inMemory()
    : tokenStorage = InMemoryTokenStorage(),
      _status = AuthSessionStatus.unauthenticated;

  final TokenStorage tokenStorage;

  AuthSessionStatus _status = AuthSessionStatus.unknown;
  AccessToken? _accessToken;

  AuthSessionStatus get status => _status;

  bool get isAuthenticated => _status == AuthSessionStatus.authenticated;

  Future<void> initialize() async {
    final rawToken = await tokenStorage.readAccessToken();
    if (rawToken == null || rawToken.trim().isEmpty) {
      _setSession(null, AuthSessionStatus.unauthenticated);
      return;
    }

    final token = AccessToken.fromJwt(rawToken.trim());
    if (token.isExpired) {
      await tokenStorage.clearAccessToken();
      _setSession(null, AuthSessionStatus.expired);
      return;
    }

    _setSession(token, AuthSessionStatus.authenticated);
  }

  Future<void> authenticate(String accessToken) async {
    final token = AccessToken.fromJwt(accessToken.trim());
    if (token.value.isEmpty) {
      await signOut();
      return;
    }

    if (token.isExpired) {
      await tokenStorage.clearAccessToken();
      _setSession(null, AuthSessionStatus.expired);
      return;
    }

    await tokenStorage.saveAccessToken(token.value);
    _setSession(token, AuthSessionStatus.authenticated);
  }

  Future<void> signOut() async {
    await tokenStorage.clearAccessToken();
    _setSession(null, AuthSessionStatus.unauthenticated);
  }

  Future<String?> currentAccessToken() async {
    final token = _accessToken;
    if (token == null) {
      return null;
    }

    if (token.isExpired) {
      await tokenStorage.clearAccessToken();
      _setSession(null, AuthSessionStatus.expired);
      return null;
    }

    return token.value;
  }

  void _setSession(AccessToken? accessToken, AuthSessionStatus status) {
    _accessToken = accessToken;
    _status = status;
    notifyListeners();
  }
}
