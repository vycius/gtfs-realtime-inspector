import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';

class InspectCubit extends Cubit<InspectScreenState> {
  InspectCubit(super.initialState);

  void selectTripDescriptor(
    TripDescriptor? tripDescriptor,
  ) {
    if (tripDescriptor == null) {
      deselect();
    } else {
      _select(
        _lookupVehicleDescriptor(tripDescriptor),
        tripDescriptor,
      );
    }
  }

  void selectVehicleDescriptor(
    VehicleDescriptor? vehicleDescriptor,
  ) {
    if (vehicleDescriptor == null) {
      deselect();
    } else {
      _select(
        vehicleDescriptor,
        _lookupTripDescriptor(vehicleDescriptor),
      );
    }
  }

  void deselect() {
    _select(null, null);
  }

  void _select(
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    emit(
      state.copyWith(
        selectedVehicleDescriptor: vehicleDescriptor,
        selectedTripDescriptor: tripDescriptor,
        filteredTripUpdates: _filterTripUpdates(
          vehicleDescriptor,
          tripDescriptor,
        ),
        filteredVehiclePositions: _filterVehiclePositions(
          vehicleDescriptor,
          tripDescriptor,
        ),
        filteredAlerts: _filterAlerts(tripDescriptor),
      ),
    );
  }

  VehicleDescriptor? _lookupVehicleDescriptor(TripDescriptor tripDescriptor) {
    return state.allVehiclePositions
        .firstWhereOrNull(
          (v) => v.hasVehicle() && v.hasTrip() && v.trip == tripDescriptor,
        )
        ?.vehicle;
  }

  TripDescriptor? _lookupTripDescriptor(VehicleDescriptor vehicleDescriptor) {
    return state.allVehiclePositions
        .firstWhereOrNull(
          (v) =>
              v.hasTrip() && v.hasVehicle() && v.vehicle == vehicleDescriptor,
        )
        ?.trip;
  }

  List<VehiclePosition> _filterVehiclePositions(
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    if (vehicleDescriptor == null && tripDescriptor == null) {
      return state.allVehiclePositions;
    } else {
      return state.allVehiclePositions
          .where(
            (v) =>
                (v.hasVehicle() && v.vehicle == vehicleDescriptor) ||
                (v.hasTrip() && v.trip == tripDescriptor),
          )
          .toList();
    }
  }

  List<TripUpdate> _filterTripUpdates(
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    if (vehicleDescriptor == null && tripDescriptor == null) {
      return state.allTripUpdates;
    } else {
      return state.allTripUpdates
          .where(
            (t) =>
                (t.hasVehicle() && t.vehicle == vehicleDescriptor) ||
                (t.hasTrip() && t.trip == tripDescriptor),
          )
          .toList();
    }
  }

  List<Alert> _filterAlerts(
    TripDescriptor? selectedTripDescriptor,
  ) {
    if (selectedTripDescriptor == null) {
      return state.allAlerts;
    }

    final tripId = selectedTripDescriptor.tripId;
    final routeId = state.gtfs.routesLookup[tripId]?.routeId;

    return state.allAlerts
        .where(
          (a) => a.informedEntity
              .where(
                (i) => i.trip.tripId == tripId || (i.trip.routeId == routeId),
              )
              .isNotEmpty,
        )
        .toList();
  }
}
