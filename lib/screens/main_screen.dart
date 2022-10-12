import 'package:flutter/material.dart';
import 'package:gtfs_realtime_inspector/screens/code_view.dart';
import 'package:gtfs_realtime_inspector/screens/vehicles_map.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';
import 'package:gtfs_realtime_inspector/widgets/app_future_builder.dart';
import 'package:split_view/split_view.dart';

class MainScreen extends StatelessWidget {
  final gtfsUrl = 'https://www.stops.lt/vilnius/vilnius/gtfs.zip';

  final gtfsRealtimeUrls = [
    'https://www.stops.lt/vilnius/vehicle_positions.pb',
    'https://www.stops.lt/vilnius/trip_updates.pb',
    'https://www.stops.lt/vilnius/service_alerts.pb',
  ];

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        body: AppFutureBuilder<TransitData>(
          future: TransitService().fetchTransitFeeds(gtfsUrl, gtfsRealtimeUrls),
          builder: (context, data) {
            return SplitView(
              viewMode: SplitViewMode.Horizontal,
              indicator: const SplitIndicator(
                viewMode: SplitViewMode.Horizontal,
              ),
              controller: SplitViewController(
                weights: [0.4, 0.6],
              ),
              children: [
                CodeView(
                  gtfs: data.gtfs,
                  realtime: data.realtime,
                ),
                VehiclesMap(
                  vehiclePositions: data.realtime.vehiclePositions,
                  tripIdToRouteIdLookup: data.gtfs.tripIdToRouteIdLookup,
                  routesLookup: data.gtfs.routesLookup,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
