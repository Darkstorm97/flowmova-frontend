import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses localhost backend as default API base URL', () {
    expect(AppEnvironment.defaultApiBaseUrl, 'http://localhost:8080');
    expect(AppEnvironment.current.apiBaseUrl, 'http://localhost:8080');
  });

  test('resolves API URI from relative and absolute paths', () {
    const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

    expect(
      environment.resolveApiUri('/api/companies').toString(),
      'http://localhost:8080/api/companies',
    );
    expect(
      environment.resolveApiUri('api/users/me').toString(),
      'http://localhost:8080/api/users/me',
    );
  });

  test('keeps existing base path and serializes query parameters', () {
    const environment = AppEnvironment(
      apiBaseUrl: 'https://api.flowmova.com/v1',
    );

    expect(
      environment.resolveApiUri('/companies', {
        'page': 0,
        'size': 20,
        'search': 'restaurant',
        'ignored': null,
      }).toString(),
      'https://api.flowmova.com/v1/companies?page=0&size=20&search=restaurant',
    );
  });
}
