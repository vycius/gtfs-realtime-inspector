import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

part 'models.freezed.dart';

@freezed
class InspectScreenState with _$InspectScreenState {
  const factory InspectScreenState({
    required String gtfsUrl,
    required List<String> gtfsRealtimeUrls,
    required GTFSData gtfs,
    required List<TripUpdate> allTripUpdates,
    required List<VehiclePosition> allVehiclePositions,
    required List<Alert> allAlerts,
    required List<TripUpdate> filteredTripUpdates,
    required List<VehiclePosition> filteredVehiclePositions,
    required List<Alert> filteredAlerts,
    VehicleDescriptor? selectedVehicleDescriptor,
    TripDescriptor? selectedTripDescriptor,
  }) = _InspectScreenState;
}

class GTFSData {
  final Map<String, GTFSRoute> routesLookup;
  final Map<String, String> tripIdToRouteIdLookup;

  const GTFSData({
    required this.tripIdToRouteIdLookup,
    required this.routesLookup,
  });
}

class GTFSRoute {
  final String routeId;
  final String? routeShortName;
  final String? routeLongName;
  final String? routeColor;
  final String? routeTextColor;

  GTFSRoute({
    required this.routeId,
    this.routeShortName,
    this.routeLongName,
    this.routeColor,
    this.routeTextColor,
  });

  Color _hexToColor(String hexString) {
    var hexColor = hexString;
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }

    throw Exception('Unable to pass color $hexString');
  }

  Color? get parsedRouteColor {
    if (routeColor != null) {
      return _hexToColor(routeColor!);
    }

    return null;
  }

  Color? get parsedRouteTextColor {
    if (routeTextColor != null) {
      return _hexToColor(routeTextColor!);
    }

    return null;
  }
}

class GTFSRealtimeData {
  final List<TripUpdate> tripUpdates;
  final List<VehiclePosition> vehiclePositions;
  final List<Alert> alerts;

  const GTFSRealtimeData({
    required this.tripUpdates,
    required this.vehiclePositions,
    required this.alerts,
  });
}

class TransitData {
  final String gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  final GTFSData gtfs;
  final GTFSRealtimeData realtime;

  TransitData({
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
    required this.gtfs,
    required this.realtime,
  });
}
