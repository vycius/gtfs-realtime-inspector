import 'dart:ui';

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

Color hexToColor(String hexString) {
  var hexColor = hexString;
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  if (hexColor.length == 8) {
    return Color(int.parse('0x$hexColor'));
  }

  throw Exception('Unable to pass color $hexString');
}
