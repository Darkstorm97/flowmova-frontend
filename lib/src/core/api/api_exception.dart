import 'api_error_response.dart';
import 'api_field_error.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const [],
    this.technicalMessage,
    this.isNetworkError = false,
  });

  factory ApiException.fromErrorResponse(
    ApiErrorResponse errorResponse, {
    int? fallbackStatusCode,
  }) {
    return ApiException(
      statusCode: errorResponse.status ?? fallbackStatusCode,
      code: errorResponse.code,
      message: errorResponse.message,
      fieldErrors: errorResponse.fieldErrors,
    );
  }

  factory ApiException.network(Object error) {
    return ApiException(
      message:
          'Impossible de joindre le serveur. Verifiez votre connexion puis reessayez.',
      code: 'NETWORK_ERROR',
      technicalMessage: error.toString(),
      isNetworkError: true,
    );
  }

  factory ApiException.timeout() {
    return const ApiException(
      message: 'Le serveur met trop de temps a repondre. Reessayez plus tard.',
      code: 'TIMEOUT',
      isNetworkError: true,
    );
  }

  final int? statusCode;
  final String? code;
  final String message;
  final List<ApiFieldError> fieldErrors;
  final String? technicalMessage;
  final bool isNetworkError;

  String? fieldMessage(String field) {
    for (final fieldError in fieldErrors) {
      if (fieldError.field == field) {
        return fieldError.message;
      }
    }
    return null;
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
