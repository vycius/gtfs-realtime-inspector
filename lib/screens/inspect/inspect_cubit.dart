import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/transit_service.dart';

class InspectCubit extends Cubit<InspectScreenState> {
  StreamSubscription<GTFSRealtimeData>? _realtimeFeedsSubscription;

  InspectCubit(super.initialState);

  Future<void> enableSync() async {
    await _closeRealtimeFeedsSubscription();

    _realtimeFeedsSubscription = Stream.periodic(
      const Duration(seconds: 20),
      (_) {
        return TransitService().fetchGtfRealtimeData(
          state.gtfsRealtimeUrls,
        );
      },
    ).asyncMap((e) => e).listen(
      (rt) {
        print('Synced');
        emit(
          state.copyWith(
            realtimeSyncState: RealtimeSyncState.syncing,
            allTripUpdates: rt.tripUpdates,
            allVehiclePositions: rt.vehiclePositions,
            allAlerts: rt.alerts,
            filteredTripUpdates: _filterTripUpdates(
              rt.tripUpdates,
              state.selectedVehicleDescriptor,
              state.selectedTripDescriptor,
            ),
            filteredVehiclePositions: _filterVehiclePositions(
              rt.vehiclePositions,
              state.selectedVehicleDescriptor,
              state.selectedTripDescriptor,
            ),
            filteredAlerts: _filterAlerts(
              rt.alerts,
              state.gtfs.routesLookup,
              state.selectedTripDescriptor,
            ),
          ),
        );
      },
    );

    emit(
      state.copyWith(realtimeSyncState: RealtimeSyncState.syncing),
    );
  }

  Future<void> disableSync() async {
    return _closeRealtimeFeedsSubscription().then(
      (_) => emit(
        state.copyWith(realtimeSyncState: RealtimeSyncState.disabled),
      ),
    );
  }

  void deselect() {
    select(null, null);
  }

  void select(
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    emit(
      state.copyWith(
        selectedVehicleDescriptor: vehicleDescriptor,
        selectedTripDescriptor: tripDescriptor,
        filteredTripUpdates: _filterTripUpdates(
          state.allTripUpdates,
          vehicleDescriptor,
          tripDescriptor,
        ),
        filteredVehiclePositions: _filterVehiclePositions(
          state.allVehiclePositions,
          vehicleDescriptor,
          tripDescriptor,
        ),
        filteredAlerts: _filterAlerts(
          state.allAlerts,
          state.gtfs.routesLookup,
          tripDescriptor,
        ),
      ),
    );
  }

  static List<VehiclePosition> _filterVehiclePositions(
    List<VehiclePosition> vehiclePositions,
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    if (vehicleDescriptor == null && tripDescriptor == null) {
      return vehiclePositions;
    } else {
      return vehiclePositions
          .where(
            (v) =>
                (v.hasVehicle() && v.vehicle == vehicleDescriptor) ||
                (v.hasTrip() && v.trip == tripDescriptor),
          )
          .toList();
    }
  }

  static List<TripUpdate> _filterTripUpdates(
    List<TripUpdate> tripUpdates,
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    if (vehicleDescriptor == null && tripDescriptor == null) {
      return tripUpdates;
    } else {
      return tripUpdates
          .where(
            (t) =>
                (t.hasVehicle() && t.vehicle == vehicleDescriptor) ||
                (t.hasTrip() && t.trip == tripDescriptor),
          )
          .toList();
    }
  }

  static List<Alert> _filterAlerts(
    List<Alert> alerts,
    Map<String, GTFSRoute> routesLookup,
    TripDescriptor? selectedTripDescriptor,
  ) {
    if (selectedTripDescriptor == null) {
      return alerts;
    }

    final tripId = selectedTripDescriptor.tripId;
    final routeId = routesLookup[tripId]?.routeId;

    return alerts
        .where(
          (a) => a.informedEntity
              .where(
                (i) => i.trip.tripId == tripId || (i.trip.routeId == routeId),
              )
              .isNotEmpty,
        )
        .toList();
  }

  Future<void> _closeRealtimeFeedsSubscription() async {
    await _realtimeFeedsSubscription?.cancel();
    _realtimeFeedsSubscription = null;
  }

  @override
  Future<void> close() async {
    await _closeRealtimeFeedsSubscription();

    return super.close();
  }
}
