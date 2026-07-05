import 'dart:convert';

import 'package:flowmova_frontend/src/core/session/auth_session_controller.dart';
import 'package:flowmova_frontend/src/core/session/in_memory_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initializes unauthenticated when no token is stored', () async {
    final controller = AuthSessionController(
      tokenStorage: InMemoryTokenStorage(),
    );

    await controller.initialize();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.isAuthenticated, isFalse);
    expect(await controller.currentAccessToken(), isNull);
  });

  test('authenticates and provides current access token', () async {
    final storage = InMemoryTokenStorage();
    final controller = AuthSessionController(tokenStorage: storage);
    final token = _jwt(
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    await controller.authenticate(token);

    expect(controller.status, AuthSessionStatus.authenticated);
    expect(controller.isAuthenticated, isTrue);
    expect(await controller.currentAccessToken(), token);
    expect(await storage.readAccessToken(), token);
  });

  test('restores a valid stored token on initialize', () async {
    final storage = InMemoryTokenStorage();
    final token = _jwt(
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    await storage.saveAccessToken(token);
    final controller = AuthSessionController(tokenStorage: storage);

    await controller.initialize();

    expect(controller.status, AuthSessionStatus.authenticated);
    expect(await controller.currentAccessToken(), token);
  });

  test('clears an expired stored token on initialize', () async {
    final storage = InMemoryTokenStorage();
    final token = _jwt(
      expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    await storage.saveAccessToken(token);
    final controller = AuthSessionController(tokenStorage: storage);

    await controller.initialize();

    expect(controller.status, AuthSessionStatus.expired);
    expect(await controller.currentAccessToken(), isNull);
    expect(await storage.readAccessToken(), isNull);
  });

  test('sign out clears session and storage', () async {
    final storage = InMemoryTokenStorage();
    final controller = AuthSessionController(tokenStorage: storage);
    await controller.authenticate('opaque-token');

    await controller.signOut();

    expect(controller.status, AuthSessionStatus.unauthenticated);
    expect(controller.isAuthenticated, isFalse);
    expect(await storage.readAccessToken(), isNull);
  });
}

String _jwt({required DateTime expiresAt}) {
  final header = _encode({'alg': 'none', 'typ': 'JWT'});
  final payload = _encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.signature';
}

String _encode(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}
