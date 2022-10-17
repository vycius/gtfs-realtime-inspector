import 'dart:ui';

import 'package:flutter_form_bloc/flutter_form_bloc.dart';

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

String timestampToFormattedDateTime(int timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  return dateFormat.format(dateTime.toLocal());
}
