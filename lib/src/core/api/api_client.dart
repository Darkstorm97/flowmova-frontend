import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import 'api_error_response.dart';
import 'api_exception.dart';

typedef AccessTokenProvider = FutureOr<String?> Function();

class ApiClient {
  ApiClient({
    this.environment = AppEnvironment.current,
    http.Client? httpClient,
    this._accessTokenProvider,
    this._timeout = const Duration(seconds: 20),
  }) : _httpClient = httpClient ?? http.Client();

  final AppEnvironment environment;
  final http.Client _httpClient;
  final AccessTokenProvider? _accessTokenProvider;
  final Duration _timeout;

  Future<Object?> get(String path, {Map<String, dynamic>? queryParameters}) {
    return request('GET', path, queryParameters: queryParameters);
  }

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return request('POST', path, body: body, queryParameters: queryParameters);
  }

  Future<Object?> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return request('PUT', path, body: body, queryParameters: queryParameters);
  }

  Future<Object?> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) {
    return request('PATCH', path, body: body, queryParameters: queryParameters);
  }

  Future<Object?> delete(String path, {Map<String, dynamic>? queryParameters}) {
    return request('DELETE', path, queryParameters: queryParameters);
  }

  Future<Object?> request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final request = http.Request(
      method,
      environment.resolveApiUri(path, queryParameters),
    );
    request.headers.addAll(await _headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException catch (error) {
      throw ApiException.network(error);
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken.trim()}';
    }

    return headers;
  }

  Object? _decodeResponse(http.Response response) {
    if (response.statusCode == 204 || response.body.trim().isEmpty) {
      if (_isSuccess(response.statusCode)) {
        return null;
      }
    }

    final decodedBody = _decodeJson(response.body);

    if (_isSuccess(response.statusCode)) {
      return decodedBody;
    }

    if (decodedBody is Map<String, dynamic>) {
      throw ApiException.fromErrorResponse(
        ApiErrorResponse.fromJson(decodedBody),
        fallbackStatusCode: response.statusCode,
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Une erreur est survenue. Reessayez plus tard.',
      technicalMessage: response.body,
    );
  }

  Object? _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw ApiException(
        code: 'INVALID_JSON',
        message: 'La reponse du serveur est illisible.',
        technicalMessage: error.toString(),
      );
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
