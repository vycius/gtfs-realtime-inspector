bool isValidUrl(String url) {
  final uri = Uri.tryParse(url);

  return uri != null && uri.hasAbsolutePath && uri.scheme.startsWith('http');
}
