import 'dart:convert';

class AccessToken {
  const AccessToken({required this.value, this.expiresAt});

  factory AccessToken.fromJwt(String value) {
    return AccessToken(value: value, expiresAt: _readExpiresAt(value));
  }

  final String value;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiration = expiresAt;
    if (expiration == null) {
      return false;
    }
    return !DateTime.now().toUtc().isBefore(expiration);
  }

  static DateTime? _readExpiresAt(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decodedPayload = jsonDecode(payload);
      if (decodedPayload is! Map<String, dynamic>) {
        return null;
      }

      final exp = decodedPayload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
