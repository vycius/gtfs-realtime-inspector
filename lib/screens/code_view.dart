import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/code_view_cubit.dart';
import 'package:gtfs_realtime_inspector/transit_service.dart';

class CodeView extends StatelessWidget {
  final GTFSData gtfs;
  final GTFSRealtimeData realtime;

  const CodeView({super.key, required this.gtfs, required this.realtime});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, VehiclePosition?>(
      builder: (context, selectedVehiclePosition) {
        return _CodeViewBody(
          tripUpdates: _filterTripUpdates(selectedVehiclePosition),
          vehiclePositions: _filterVehiclePositions(selectedVehiclePosition),
          alerts: _filterAlerts(selectedVehiclePosition),
          selectedVehiclePosition: selectedVehiclePosition,
        );
      },
    );
  }

  List<VehiclePosition> _filterVehiclePositions(
    VehiclePosition? selectedVehiclePosition,
  ) {
    if (selectedVehiclePosition == null) {
      return realtime.vehiclePositions;
    } else {
      return realtime.vehiclePositions
          .where((v) => v.vehicle.id == selectedVehiclePosition.vehicle.id)
          .toList();
    }
  }

  List<TripUpdate> _filterTripUpdates(
    VehiclePosition? selectedVehiclePosition,
  ) {
    if (selectedVehiclePosition == null) {
      return realtime.tripUpdates;
    } else {
      return realtime.tripUpdates
          .where((t) => t.vehicle.id == selectedVehiclePosition.vehicle.id)
          .toList();
    }
  }

  List<Alert> _filterAlerts(
    VehiclePosition? selectedVehiclePosition,
  ) {
    if (selectedVehiclePosition == null) {
      return realtime.alerts;
    } else {
      final tripId = selectedVehiclePosition.trip.tripId;
      final routeId = gtfs.routesLookup[tripId]?.routeId;

      return realtime.alerts
          .where(
            (a) => a.informedEntity
                .where(
                  (i) => i.trip.tripId == tripId || (i.trip.routeId == routeId),
                )
                .isNotEmpty,
          )
          .toList();
    }
  }
}

class _CodeViewBody extends StatelessWidget {
  final List<TripUpdate> tripUpdates;
  final List<VehiclePosition> vehiclePositions;
  final List<Alert> alerts;
  final VehiclePosition? selectedVehiclePosition;

  const _CodeViewBody({
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
                        context.read<FilterCubit>().deselectVehicle(),
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
