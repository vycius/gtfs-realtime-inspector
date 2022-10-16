import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:go_router/go_router.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';

class CodeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectCubit, InspectScreenState>(
      builder: (context, state) {
        return _CodeViewBody(
          gtfsUrl: state.gtfsUrl,
          gtfsRealtimeUrls: state.gtfsRealtimeUrls,
          tripUpdates: state.filteredTripUpdates,
          vehiclePositions: state.filteredVehiclePositions,
          alerts: state.filteredAlerts,
          selectedVehiclePosition: state.selectedVehiclePosition,
        );
      },
    );
  }
}

class _CodeViewBody extends StatelessWidget {
  final String gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  final List<TripUpdate> tripUpdates;
  final List<VehiclePosition> vehiclePositions;
  final List<Alert> alerts;
  final VehiclePosition? selectedVehiclePosition;

  const _CodeViewBody({
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
    required this.tripUpdates,
    required this.vehiclePositions,
    required this.alerts,
    required this.selectedVehiclePosition,
  });

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
                text: 'Trip updates (${tripUpdates.length})',
              ),
              Tab(
                text: 'Vehicle positions (${vehiclePositions.length})',
              ),
              Tab(
                text: 'Service alerts (${alerts.length})',
              ),
            ],
            indicatorSize: TabBarIndicatorSize.label,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                context.go(
                  context.namedLocation(
                    'info',
                    queryParams: {
                      'gtfs_url': gtfsUrl,
                      'gtfs_realtime_urls': gtfsRealtimeUrls,
                    },
                  ),
                );
              },
            )
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _CodeTab<TripUpdate>(
                  entities: tripUpdates,
                  protoJsonBuilder: (e) => e.toProto3Json(),
                ),
                _CodeTab<VehiclePosition>(
                  entities: vehiclePositions,
                  protoJsonBuilder: (e) => e.toProto3Json(),
                ),
                _CodeTab<Alert>(
                  entities: alerts,
                  protoJsonBuilder: (e) => e.toProto3Json(),
                ),
              ],
            ),
            if (selectedVehiclePosition != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                  child: Chip(
                    label: Text(
                      'Vehicle: ${selectedVehiclePosition?.vehicle.id}',
                    ),
                    deleteIcon: const Icon(Icons.close),
                    deleteButtonTooltipMessage: 'Deselect',
                    onDeleted: () =>
                        context.read<InspectCubit>().deselectVehicle(),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _CodeTab<T> extends StatelessWidget {
  final List<T> entities;
  final Object? Function(T entity) protoJsonBuilder;

  const _CodeTab({
    super.key,
    required this.entities,
    required this.protoJsonBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final jsonEncoder = JsonEncoder.withIndent(' ' * 3);
    return ListView.separated(
      itemCount: entities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entity = entities[index];
        final json = jsonEncoder.convert(protoJsonBuilder(entity));

        return HighlightView(
          json,
          language: 'json',
          padding: const EdgeInsets.all(8),
          theme: MediaQuery.of(context).platformBrightness == Brightness.light
              ? githubTheme
              : darculaTheme,
        );
      },
    );
  }
}
