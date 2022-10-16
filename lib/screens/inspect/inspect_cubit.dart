import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';

class InspectCubit extends Cubit<InspectScreenState> {
  InspectCubit(super.initialState);

  void selectVehiclePosition(VehiclePosition vehiclePosition) {
    emit(
      state.copyWith(
        selectedVehiclePosition: vehiclePosition,
        filteredTripUpdates: _filterTripUpdates(vehiclePosition),
        filteredVehiclePositions: _filterVehiclePositions(vehiclePosition),
        filteredAlerts: _filterAlerts(vehiclePosition),
      ),
    );
  }

  void deselectVehicle() {
    emit(
      state.copyWith(
        selectedVehiclePosition: null,
        filteredTripUpdates: state.allTripUpdates,
        filteredVehiclePositions: state.allVehiclePositions,
        filteredAlerts: state.allAlerts,
      ),
    );
  }

  List<VehiclePosition> _filterVehiclePositions(
    VehiclePosition selectedVehiclePosition,
  ) {
    return state.allVehiclePositions
        .where((v) => v.vehicle.id == selectedVehiclePosition.vehicle.id)
        .toList();
  }

  List<TripUpdate> _filterTripUpdates(
    VehiclePosition selectedVehiclePosition,
  ) {
    return state.allTripUpdates
        .where((t) => t.vehicle.id == selectedVehiclePosition.vehicle.id)
        .toList();
  }

  List<Alert> _filterAlerts(
    VehiclePosition selectedVehiclePosition,
  ) {
    final tripId = selectedVehiclePosition.trip.tripId;
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
