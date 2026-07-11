String? publicLocationSlugFromQrValue(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return null;
  }

  return _slugFromUri(value) ?? _slugFromDirectValue(value);
}

String? _slugFromUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) {
    return null;
  }

  final querySlug = _cleanSlug(uri.queryParameters['slug']);
  if (querySlug != null) {
    return querySlug;
  }

  final matrixSlug = _matrixParameter(uri.toString(), 'slug');
  if (matrixSlug != null) {
    return matrixSlug;
  }

  if (uri.fragment.trim().isNotEmpty) {
    final fragment = uri.fragment.startsWith('/')
        ? uri.fragment
        : '/${uri.fragment}';
    final fragmentSlug = _slugFromUri(fragment);
    if (fragmentSlug != null) {
      return fragmentSlug;
    }
  }

  final path = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (path.length >= 3 &&
      path[path.length - 3] == 'public' &&
      path[path.length - 2] == 'locations') {
    return _cleanSlug(path.last);
  }

  return null;
}

String? _slugFromDirectValue(String value) {
  if (value.contains('/') || value.contains('?') || value.contains('#')) {
    return null;
  }
  return _cleanSlug(value);
}

String? _matrixParameter(String value, String key) {
  final match = RegExp('(?:^|;)$key=([^;?/#]+)').firstMatch(value);
  final raw = match?.group(1);
  if (raw == null) {
    return null;
  }
  return _cleanSlug(Uri.decodeComponent(raw));
}

String? _cleanSlug(String? value) {
  final slug = value?.trim();
  if (slug == null || slug.isEmpty) {
    return null;
  }
  if (!RegExp(r'^[A-Za-z0-9._~-]{2,160}$').hasMatch(slug)) {
    return null;
  }
  return slug;
}
