import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:latlong2/latlong.dart';

class VehiclesMap extends StatefulWidget {
  final LatLng? center;

  const VehiclesMap({required this.center});

  @override
  State<VehiclesMap> createState() => _VehiclesMapState();
}

class _VehiclesMapState extends State<VehiclesMap> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<InspectCubit, InspectScreenState>(
      listener: (_, state) {
        final selectedVehicleDescriptor = state.selectedVehicleDescriptor;

        if (selectedVehicleDescriptor != null) {
          final vehiclePosition = state.allVehiclePositions
              .firstWhereOrNull(
                (v) => v.hasVehicle() && v.vehicle == selectedVehicleDescriptor,
              )
              ?.position;

          if (vehiclePosition != null) {
            _mapController.move(
              LatLng(
                vehiclePosition.latitude,
                vehiclePosition.longitude,
              ),
              _mapController.zoom,
            );
          }
        }
      },
      child: FlutterMap(
        options: MapOptions(
          center: widget.center,
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          maxZoom: 18,
        ),
        nonRotatedChildren: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'lt.transit.transit',
          ),
          BlocBuilder<InspectCubit, InspectScreenState>(
            builder: (context, state) {
              return MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: _buildMarkers(
                    vehiclePositions: state.allVehiclePositions,
                    routesLookup: state.gtfs.routesLookup,
                    tripIdToRouteIdLookup: state.gtfs.tripIdToRouteIdLookup,
                  ),
                  anchor: AnchorPos.align(AnchorAlign.center),
                  disableClusteringAtZoom: 13,
                  builder: (BuildContext context, List<Marker> markers) {
                    return FloatingActionButton(
                      onPressed: null,
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(markers.length.toString()),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          AttributionWidget.defaultWidget(
            source: 'OpenStreetMap contributors',
          ),
        ],
        mapController: _mapController,
      ),
    );
  }

  List<Marker> _buildMarkers({
    required List<VehiclePosition> vehiclePositions,
    required Map<String, GTFSRoute> routesLookup,
    required Map<String, String> tripIdToRouteIdLookup,
  }) {
    return [
      for (final vehiclePosition in vehiclePositions)
        Marker(
          key: ObjectKey(vehiclePosition),
          point: LatLng(
            vehiclePosition.position.latitude,
            vehiclePosition.position.longitude,
          ),
          anchorPos: AnchorPos.align(AnchorAlign.center),
          builder: (context) {
            return GestureDetector(
              onTap: () {
                final vehicleDescriptor = vehiclePosition.hasVehicle()
                    ? vehiclePosition.vehicle
                    : null;

                final tripDescriptor =
                    vehiclePosition.hasTrip() ? vehiclePosition.trip : null;

                return context.read<InspectCubit>().select(
                      vehicleDescriptor,
                      tripDescriptor,
                    );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _VehicleIcon(
                  vehiclePosition: vehiclePosition,
                  tripIdToRouteIdLookup: tripIdToRouteIdLookup,
                  routesLookup: routesLookup,
                ),
              ),
            );
          },
        ),
    ];
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _VehicleIcon extends StatelessWidget {
  final VehiclePosition vehiclePosition;
  final Map<String, String> tripIdToRouteIdLookup;
  final Map<String, GTFSRoute> routesLookup;

  _VehicleIcon({
    required this.vehiclePosition,
    required this.tripIdToRouteIdLookup,
    required this.routesLookup,
  }) : super(key: ObjectKey(vehiclePosition));

  @override
  Widget build(BuildContext context) {
    final routeId = tripIdToRouteIdLookup[vehiclePosition.trip.tripId];
    final route = (routeId != null) ? routesLookup[routeId] : null;

    final routeColor = route?.routeColor ?? Colors.indigo;

    final angle = degToRadian(vehiclePosition.position.bearing) + pi * 3 / 4;

    return Transform.rotate(
      angle: angle,
      child: Material(
        elevation: 2,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(200),
          bottomRight: Radius.circular(200),
          topLeft: Radius.circular(200),
        ),
        color: routeColor,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Transform.rotate(
                angle: -angle,
                child: _buildVehicleBody(route),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleBody(GTFSRoute? route) {
    final routeTextColor = route?.routeTextColor ?? Colors.white;

    if (route == null) {
      return Icon(
        Icons.directions_bus,
        size: 15,
        color: routeTextColor,
      );
    } else {
      return Text(
        route.routeShortName ?? '?',
        maxLines: 1,
        style: TextStyle(color: routeTextColor),
      );
    }
  }
}
