import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';

class InspectCubit extends Cubit<VehiclePosition?> {
  InspectCubit() : super(null);

  void selectVehicle(VehiclePosition vehiclePosition) => emit(vehiclePosition);

  void deselectVehicle() => emit(null);
}

class InspectScreenState {
  final GTFSData gtfs;

  final List<TripUpdate> allTripUpdates;
  final List<VehiclePosition> allVehiclePositions;
  final List<Alert> allAlerts;

  final VehiclePosition? selectedVehiclePosition;

  final List<TripUpdate> filteredTripUpdates;
  final List<VehiclePosition> filteredVehiclePositions;
  final List<Alert> filteredAlerts;

  const InspectScreenState({
    required this.gtfs,
    required this.allTripUpdates,
    required this.allVehiclePositions,
    required this.allAlerts,
    required this.filteredTripUpdates,
    required this.filteredVehiclePositions,
    required this.filteredAlerts,
    this.selectedVehiclePosition,
  });
}
