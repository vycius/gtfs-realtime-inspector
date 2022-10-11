import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:gtfs_realtime_inspector/screens/vehicles_map.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';
import 'package:gtfs_realtime_inspector/widgets/AppFutureBuilder.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('GTFS Realtime inspector'),
        centerTitle: true,
      ),
      body: AppFutureBuilder<TransitData>(
        future: TransitService().fetchTransitFeeds(gtfsUrl, gtfsRealtimeUrls),
        builder: (context, data) {
          final rt = data.rt;

          return Stack(
            children: [
              SplitView(
                viewMode: SplitViewMode.Horizontal,
                indicator:
                    const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                controller: SplitViewController(
                  limits: [null, WeightLimit(max: 0.4)],
                ),
                children: [
                  VehiclesMap(
                    vehiclePositions: rt.vehiclePositions,
                    tripIdToRouteIdLookup: data.gtfs.tripIdToRouteIdLookup,
                    routesLookup: data.gtfs.routesLookup,
                  ),
                  ListView.separated(
                    itemCount: rt.vehiclePositions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final vehiclePosition = rt.vehiclePositions[index];
                      final json = JsonEncoder.withIndent(' ' * 3).convert(
                        vehiclePosition.toProto3Json(),
                      );

                      return ListTile(
                        title: HighlightView(
                          json,
                          language: 'json',
                          theme: githubTheme,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Chip(
                        avatar: const CircleAvatar(
                          child: Icon(Icons.schedule),
                        ),
                        label: Text('Trip updates: ${rt.tripUpdates.length}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Chip(
                        avatar: const CircleAvatar(
                          child: Icon(Icons.directions_bus),
                        ),
                        label: Text(
                          'Vehicle positions: ${rt.vehiclePositions.length}',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Chip(
                        avatar: const CircleAvatar(
                          child: Icon(
                            Icons.bus_alert,
                            size: 16,
                          ),
                        ),
                        label: Text(
                          'Service alerts: ${rt.alerts.length}',
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
