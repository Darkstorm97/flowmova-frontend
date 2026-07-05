class AppEnvironment {
  const AppEnvironment({required this.apiBaseUrl});

  static const String defaultApiBaseUrl = 'http://localhost:8080';

  static const AppEnvironment current = AppEnvironment(
    apiBaseUrl: String.fromEnvironment(
      'FLOWMOVA_API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    ),
  );

  final String apiBaseUrl;

  Uri resolveApiUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUri = Uri.parse(apiBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = baseUri.path.endsWith('/')
        ? baseUri.path
        : '${baseUri.path}/';

    return baseUri.replace(
      path: '$basePath$normalizedPath',
      queryParameters: _normalizeQueryParameters(queryParameters),
    );
  }

  Map<String, String>? _normalizeQueryParameters(
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return null;
    }

    final normalized = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      normalized[entry.key] = value.toString();
    }

    return normalized.isEmpty ? null : normalized;
  }
}
