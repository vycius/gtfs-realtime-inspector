import 'package:flutter/material.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/code_view.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/vehicles_map.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';
import 'package:gtfs_realtime_inspector/widgets/app_future_builder.dart';
import 'package:split_view/split_view.dart';

class InspectScreen extends StatelessWidget {
  final String gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  const InspectScreen({
    super.key,
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
