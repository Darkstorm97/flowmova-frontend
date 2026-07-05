import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flowmova_frontend/src/features/auth/data/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('register sends the backend register payload', () async {
    late http.BaseRequest capturedRequest;
    late String capturedBody;
    final gateway = BackendAuthGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedRequest = request;
          capturedBody = await bodyStream.bytesToString();
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'id': 'user-1',
                  'email': 'ada@flowmova.test',
                  'firstName': 'Ada',
                  'lastName': 'Lovelace',
                  'status': 'ACTIVE',
                  'createdAt': '2026-07-05T00:00:00Z',
                }),
              ),
            ),
            201,
          );
        }),
      ),
    );

    final result = await gateway.register(
      const RegisterUserCommand(
        email: ' ada@flowmova.test ',
        password: 'Password123',
        firstName: ' Ada ',
        lastName: ' Lovelace ',
      ),
    );

    expect(capturedRequest.url.path, '/api/auth/register');
    expect(jsonDecode(capturedBody), {
      'email': 'ada@flowmova.test',
      'password': 'Password123',
      'firstName': 'Ada',
      'lastName': 'Lovelace',
    });
    expect(result.email, 'ada@flowmova.test');
    expect(result.status, 'ACTIVE');
  });

  test('login returns token information', () async {
    late String capturedBody;
    final gateway = BackendAuthGateway(
      ApiClient(
        environment: environment,
        httpClient: MockClient.streaming((request, bodyStream) async {
          capturedBody = await bodyStream.bytesToString();
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'accessToken': 'jwt-token',
                  'tokenType': 'Bearer',
                  'expiresIn': 3600,
                }),
              ),
            ),
            200,
          );
        }),
      ),
    );

    final result = await gateway.login(
      const LoginUserCommand(
        email: ' ada@flowmova.test ',
        password: 'Password123',
      ),
    );

    expect(jsonDecode(capturedBody), {
      'email': 'ada@flowmova.test',
      'password': 'Password123',
    });
    expect(result.accessToken, 'jwt-token');
    expect(result.tokenType, 'Bearer');
    expect(result.expiresIn, 3600);
  });
}
