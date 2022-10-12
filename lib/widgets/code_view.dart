import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';

class CodeView extends StatelessWidget {
  final GTFSData gtfs;
  final GTFSRealtimeData realtime;

  const CodeView({super.key, required this.gtfs, required this.realtime});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GTFS Realtime inspector'),
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Trip updates (${realtime.tripUpdates.length})',
              ),
              Tab(
                text: 'Vehicle positions (${realtime.vehiclePositions.length})',
              ),
              Tab(
                text: 'Service alerts (${realtime.alerts.length})',
              ),
            ],
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: TabBarView(
          children: [
            CodeTab<TripUpdate>(
              entities: realtime.tripUpdates,
              protoJsonBuilder: (e) => e.toProto3Json(),
            ),
            CodeTab<VehiclePosition>(
              entities: realtime.vehiclePositions,
              protoJsonBuilder: (e) => e.toProto3Json(),
            ),
            CodeTab<Alert>(
              entities: realtime.alerts,
              protoJsonBuilder: (e) => e.toProto3Json(),
            ),
          ],
        ),
      ),
    );
  }
}

class CodeTab<T> extends StatelessWidget {
  final List<T> entities;
  final Object? Function(T entity) protoJsonBuilder;

  const CodeTab({
    super.key,
    required this.entities,
    required this.protoJsonBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final jsonEncoder = JsonEncoder.withIndent(' ' * 3);
    return ListView.separated(
      itemCount: entities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final entity = entities[index];
        final json = jsonEncoder.convert(protoJsonBuilder(entity));

        return HighlightView(
          json,
          language: 'json',
          padding: const EdgeInsets.all(8),
          theme: githubTheme,
        );
      },
    );
  }
}
