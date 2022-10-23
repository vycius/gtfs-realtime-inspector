import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

part 'models.freezed.dart';

@freezed
class InspectScreenState with _$InspectScreenState {
  const factory InspectScreenState({
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
    @Default(RealtimeSyncState.disabled) RealtimeSyncState realtimeSyncState,
  }) = _InspectScreenState;
}

class GTFSData {
  final String? url;
  final Map<String, GTFSRoute> routesLookup;
  final Map<String, String> tripIdToRouteIdLookup;
  final String? warning;

  const GTFSData({
    required this.url,
    required this.tripIdToRouteIdLookup,
    required this.routesLookup,
    this.warning,
  });
}

class GTFSRoute {
  final String routeId;
  final String? routeShortName;
  final Color? routeColor;
  final Color? routeTextColor;

  const GTFSRoute({
    required this.routeId,
    this.routeShortName,
    this.routeColor,
    this.routeTextColor,
  });
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
  final List<String> gtfsRealtimeUrls;

  final GTFSData gtfs;
  final GTFSRealtimeData realtime;

  const TransitData({
    required this.gtfsRealtimeUrls,
    required this.gtfs,
    required this.realtime,
  });
}

enum RealtimeSyncState {
  disabled,
  syncing,
}
