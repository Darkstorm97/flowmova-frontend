import 'package:flowmova_frontend/src/core/session/shared_preferences_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists and clears access token', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = SharedPreferencesTokenStorage(preferences);

    await storage.saveAccessToken('token-123');
    expect(await storage.readAccessToken(), 'token-123');

    await storage.clearAccessToken();
    expect(await storage.readAccessToken(), isNull);
  });
}
