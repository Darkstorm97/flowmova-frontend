import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

class SharedPreferencesTokenStorage implements TokenStorage {
  SharedPreferencesTokenStorage(this._preferences);

  static const accessTokenKey = 'flowmova.accessToken';

  final SharedPreferences _preferences;

  @override
  Future<String?> readAccessToken() async {
    return _preferences.getString(accessTokenKey);
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    await _preferences.setString(accessTokenKey, accessToken);
  }

  @override
  Future<void> clearAccessToken() async {
    await _preferences.remove(accessTokenKey);
  }
}
