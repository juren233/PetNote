String normalizeAiBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

bool isValidAiBaseUrl(String value) {
  final normalized = normalizeAiBaseUrl(value);
  if (normalized.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return false;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return false;
  }
  if (uri.host.trim().isEmpty) {
    return false;
  }
  return true;
}
