import 'api_field_error.dart';

class ApiErrorResponse {
  const ApiErrorResponse({
    required this.status,
    required this.code,
    required this.message,
    this.timestamp,
    this.error,
    this.path,
    this.fieldErrors = const [],
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final rawFieldErrors = json['fieldErrors'];

    return ApiErrorResponse(
      timestamp: json['timestamp']?.toString(),
      status: _readInt(json['status']),
      error: json['error']?.toString(),
      code: json['code']?.toString() ?? 'API_ERROR',
      message: json['message']?.toString() ?? 'Une erreur est survenue.',
      path: json['path']?.toString(),
      fieldErrors: rawFieldErrors is List
          ? rawFieldErrors
                .whereType<Map<String, dynamic>>()
                .map(ApiFieldError.fromJson)
                .toList()
          : const [],
    );
  }

  final String? timestamp;
  final int? status;
  final String? error;
  final String code;
  final String message;
  final String? path;
  final List<ApiFieldError> fieldErrors;

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
