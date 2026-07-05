import 'dart:convert';

import 'package:flowmova_frontend/src/core/session/access_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads expiration from JWT payload', () {
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
    final token = AccessToken.fromJwt(_jwt(expiresAt: expiresAt));

    expect(token.expiresAt, isNotNull);
    expect(token.isExpired, isFalse);
  });

  test('detects expired JWT payload', () {
    final expiresAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 1),
    );
    final token = AccessToken.fromJwt(_jwt(expiresAt: expiresAt));

    expect(token.isExpired, isTrue);
  });

  test('keeps opaque tokens usable when no JWT expiration is available', () {
    final token = AccessToken.fromJwt('opaque-token');

    expect(token.expiresAt, isNull);
    expect(token.isExpired, isFalse);
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
