import 'package:flowmova_frontend/src/core/api/api_error_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps standardized backend error response', () {
    final error = ApiErrorResponse.fromJson({
      'timestamp': '2026-07-05T18:00:00Z',
      'status': 400,
      'error': 'Bad Request',
      'code': 'VALIDATION_ERROR',
      'message': 'Request validation failed',
      'path': '/api/auth/register',
      'fieldErrors': [
        {'field': 'email', 'message': 'must not be blank'},
      ],
    });

    expect(error.status, 400);
    expect(error.code, 'VALIDATION_ERROR');
    expect(error.message, 'Request validation failed');
    expect(error.path, '/api/auth/register');
    expect(error.fieldErrors.single.field, 'email');
    expect(error.fieldErrors.single.message, 'must not be blank');
  });
}
