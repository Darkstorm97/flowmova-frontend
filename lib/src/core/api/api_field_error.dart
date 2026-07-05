class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  final String field;
  final String message;
}
