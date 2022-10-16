import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:latlong2/latlong.dart';

class VehiclesMap extends StatelessWidget {
  final List<VehiclePosition> vehiclePositions;
  final Map<String, String> tripIdToRouteIdLookup;
  final Map<String, GTFSRoute> routesLookup;
  final mapController = MapController();

  VehiclesMap({
    required this.vehiclePositions,
    required this.tripIdToRouteIdLookup,
    required this.routesLookup,
  });

  MarkerLayer buildLayer() {
    return MarkerLayer(
      markers: [
        for (final vehiclePosition in vehiclePositions)
          Marker(
            key: Key('vehicle-${vehiclePosition.vehicle.id}'),
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
                child: _VehicleIcon(
                  vehiclePosition: vehiclePosition,
                  tripIdToRouteIdLookup: tripIdToRouteIdLookup,
                  routesLookup: routesLookup,
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InspectCubit, InspectScreenState>(
      listener: (_, state) {
        final selectedVehicleDescriptor = state.selectedVehicleDescriptor;
        final vehiclePosition = vehiclePositions
            .firstWhereOrNull(
              (v) => v.vehicle == selectedVehicleDescriptor,
            )
            ?.position;

        if (vehiclePosition != null) {
          mapController.move(
            LatLng(
              vehiclePosition.latitude,
              vehiclePosition.longitude,
            ),
            mapController.zoom,
          );
        }
      },
      child: FlutterMap(
        options: MapOptions(
          center: _getCenter(),
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        nonRotatedChildren: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'lt.transit.transit',
          ),
          buildLayer(),
          AttributionWidget.defaultWidget(
            source: 'OpenStreetMap contributors',
          ),
        ],
        mapController: mapController,
      ),
    );
  }

  LatLng? _getCenter() {
    if (vehiclePositions.isEmpty) {
      return null;
    }

    final points = vehiclePositions
        .map(
          (v) => LatLng(v.position.latitude, v.position.longitude),
        )
        .toList();

    return LatLngBounds.fromPoints(points).center;
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

    final routeColor = route?.parsedRouteColor ?? Colors.indigo;

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
    final routeTextColor = route?.parsedRouteTextColor ?? Colors.white;

    if (route == null) {
      return Icon(
        Icons.directions_bus,
        size: 15,
        color: routeTextColor,
      );
    } else {
      final text = route.routeShortName ?? route.routeLongName ?? '?';

      return Text(
        text,
        maxLines: 1,
        style: TextStyle(color: routeTextColor),
      );
    }
  }
}
