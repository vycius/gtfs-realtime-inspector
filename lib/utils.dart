import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:latlong2/latlong.dart';

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

LatLng? getNearestLatLngToVehiclePositionsCenter(
  List<VehiclePosition> vehiclePositions,
) {
  if (vehiclePositions.isEmpty) {
    return null;
  }

  final points = vehiclePositions
      .map(
        (v) => LatLng(v.position.latitude, v.position.longitude),
      )
      .toList();

  final center = LatLngBounds.fromPoints(points).center;

  const distance = Distance();

  return minBy<LatLng, double>(points, (p) => distance(p, center));
}

Stream<T> onceAndPeriodic<T>(
  Duration period,
  Future<T> Function(int) computation,
) async* {
  yield await computation(0);

  yield* Stream.periodic(period, (i) => computation(i + 1))
      .asyncMap((event) => event);
}
