bool isValidUrl(String url) {
  final uri = Uri.tryParse(url);

  return uri != null && uri.hasAbsolutePath && uri.scheme.startsWith('http');
}

String? urlValidator(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  } else if (isValidUrl(url)) {
    return null;
  } else {
    return 'Please enter valid URL';
  }
}
