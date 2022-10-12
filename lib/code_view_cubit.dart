import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

class FilterCubit extends Cubit<VehiclePosition?> {
  FilterCubit() : super(null);

  void selectVehicle(VehiclePosition vehiclePosition) => emit(vehiclePosition);

  void deselectVehicle() => emit(null);
}
