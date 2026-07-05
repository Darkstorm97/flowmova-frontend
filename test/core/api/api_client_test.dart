import 'dart:async';
import 'dart:convert';

import 'package:flowmova_frontend/src/core/api/api_client.dart';
import 'package:flowmova_frontend/src/core/api/api_exception.dart';
import 'package:flowmova_frontend/src/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const environment = AppEnvironment(apiBaseUrl: 'http://localhost:8080');

  test('sends JSON headers, bearer token and resolved URL', () async {
    late http.BaseRequest capturedRequest;
    final client = ApiClient(
      environment: environment,
      accessTokenProvider: () => ' token-123 ',
      httpClient: MockClient.streaming((request, bodyStream) async {
        capturedRequest = request;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"ok":true}')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await client.get(
      '/api/companies',
      queryParameters: {'page': 0},
    );

    expect(response, {'ok': true});
    expect(
      capturedRequest.url.toString(),
      'http://localhost:8080/api/companies?page=0',
    );
    expect(capturedRequest.headers['Accept'], 'application/json');
    expect(capturedRequest.headers['Content-Type'], 'application/json');
    expect(capturedRequest.headers['Authorization'], 'Bearer token-123');
  });

  test('encodes request body as JSON', () async {
    late String capturedBody;
    final client = ApiClient(
      environment: environment,
      httpClient: MockClient.streaming((request, bodyStream) async {
        capturedBody = await bodyStream.bytesToString();
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 201);
      }),
    );

    await client.post('/api/auth/login', body: {'email': 'user@test.local'});

    expect(jsonDecode(capturedBody), {'email': 'user@test.local'});
  });

  test('returns null for empty successful response', () async {
    final client = ApiClient(
      environment: environment,
      httpClient: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(const Stream.empty(), 204);
      }),
    );

    expect(await client.delete('/api/session'), isNull);
  });

  test('maps standardized backend error response to ApiException', () async {
    final client = ApiClient(
      environment: environment,
      httpClient: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'status': 400,
                'error': 'Bad Request',
                'code': 'VALIDATION_ERROR',
                'message': 'Request validation failed',
                'path': '/api/auth/register',
                'fieldErrors': [
                  {'field': 'email', 'message': 'must not be blank'},
                ],
              }),
            ),
          ),
          400,
        );
      }),
    );

    expect(
      () => client.post('/api/auth/register', body: {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.code, 'code', 'VALIDATION_ERROR')
            .having(
              (error) => error.fieldMessage('email'),
              'email field message',
              'must not be blank',
            ),
      ),
    );
  });

  test('maps non-json server error to generic ApiException', () async {
    final client = ApiClient(
      environment: environment,
      httpClient: MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(Stream.value(utf8.encode('Oops')), 500);
      }),
    );

    expect(
      () => client.get('/api/broken'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INVALID_JSON')
            .having(
              (error) => error.message,
              'message',
              'La reponse du serveur est illisible.',
            ),
      ),
    );
  });

  test('maps network errors', () async {
    final client = ApiClient(
      environment: environment,
      httpClient: MockClient.streaming((request, bodyStream) {
        throw http.ClientException('connection refused');
      }),
    );

    expect(
      () => client.get('/api/users/me'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'NETWORK_ERROR')
            .having((error) => error.isNetworkError, 'isNetworkError', true),
      ),
    );
  });

  test('maps timeout errors', () async {
    final client = ApiClient(
      environment: environment,
      timeout: const Duration(milliseconds: 1),
      httpClient: MockClient.streaming((request, bodyStream) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
      }),
    );

    expect(
      () => client.get('/api/slow'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'TIMEOUT')
            .having((error) => error.isNetworkError, 'isNetworkError', true),
      ),
    );
  });
}
