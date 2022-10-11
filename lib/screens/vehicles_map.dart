import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:latlong2/latlong.dart';

class VehiclesMap extends StatelessWidget {
  final List<VehiclePosition> vehiclePositions;

  // late Map<String, Trip> _tripLookup;
  // late Map<String, TransitRoute> _routeLookup;

  VehiclesMap({
    required this.vehiclePositions,
    // required this.trips,
    // required this.routes,
  }) {
    // _tripLookup = HashMap.fromIterables(
    //   trips.map((t) => t.trip_id),
    //   trips,
    // );
    //
    // _routeLookup = HashMap.fromIterables(
    //   routes.map((r) => r.route_id),
    //   routes,
    // );
  }

  MarkerLayerOptions buildLayer() {
    return MarkerLayerOptions(
      markers: [
        for (final vehiclePosition in vehiclePositions)
          Marker(
            key: Key('vehicle-${vehiclePosition.vehicle.id}'),
            point: LatLng(
              vehiclePosition.position.latitude,
              vehiclePosition.position.longitude,
            ),
            anchorPos: AnchorPos.align(AnchorAlign.center),
            // width: 25,
            // height: 25,
            builder: (context) {
              return _VehicleIcon(
                vehiclePosition: vehiclePosition,
              );

              return _buildVehicleIcon(
                context,
                vehiclePosition,
              );
            },
          ),
      ],
    );
  }

  Widget _buildVehicleIcon(
    BuildContext context,
    VehiclePosition vehiclePosition,
  ) {
    // final trip = _tripLookup[vehiclePosition.trip.tripId];
    // final routeId = trip?.route_id;
    // final route = (routeId != null) ? _routeLookup[routeId] : null;

    // final routeColor = route?.parsedRouteColor ?? Colors.indigo;
    // final routeTextColor = route?.parsedRouteTextColor ?? Colors.white;

    final routeColor = Colors.indigo;
    final routeTextColor = Colors.white;

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
                child: Text(
                  vehiclePosition.position.bearing.toString(),
                  maxLines: 1,
                  style: TextStyle(
                    color: routeTextColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _onPressed(BuildContext context, TransitRoute route, Trip trip) {
  //   return Navigator.pushNamed(
  //     context,
  //     NavigatorRoutes.routeTrip,
  //     arguments: TripScreenArguments(
  //       route: route,
  //       trip: trip,
  //       stop: null,
  //     ),
  //   );
  // }

  Widget _buildVehicleBody() {
    return const Icon(
      Icons.directions_bus,
      color: Colors.white,
      size: 15,
    );
    //
    // final routeShortName = route?.route_short_name;
    //
    // if (route != null && routeShortName != null) {
    //   return Padding(
    //     padding: const EdgeInsets.all(2),
    //     child: FittedBox(
    //       fit: BoxFit.scaleDown,
    //       child: Text(
    //         routeShortName,
    //         maxLines: 1,
    //       ),
    //     ),
    //   );
    // } else {
    //   return Icon(
    //     Icons.directions_bus,
    //     size: 15,
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: _getCenter(),
        // boundsOptions: FitBoundsOptions,
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'lt.transit.transit',
        ),
        buildLayer(),
      ],
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
        ),
      ],
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

  _VehicleIcon({
    required this.vehiclePosition,
  }) : super(key: ObjectKey(vehiclePosition));

  @override
  Widget build(BuildContext context) {
    // final trip = _tripLookup[vehiclePosition.trip.tripId];
    // final routeId = trip?.route_id;
    // final route = (routeId != null) ? _routeLookup[routeId] : null;

    // final routeColor = route?.parsedRouteColor ?? Colors.indigo;
    // final routeTextColor = route?.parsedRouteTextColor ?? Colors.white;

    final routeColor = Colors.indigo;
    final routeTextColor = Colors.white;

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
                child: Icon(
                  Icons.directions_bus,
                  size: 15,
                  color: routeTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
