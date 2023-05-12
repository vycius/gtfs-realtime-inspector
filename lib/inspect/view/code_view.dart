import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:go_router/go_router.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/extensions.dart';
import 'package:gtfs_realtime_inspector/inspect/cubit/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/inspect/models/models.dart';
import 'package:gtfs_realtime_inspector/utils.dart';

class CodeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectCubit, InspectScreenState>(
      builder: (context, state) {
        return _CodeViewBody(
          gtfs: state.gtfs,
          gtfsRealtimeUrls: state.gtfsRealtimeUrls,
          tripUpdates: state.filteredTripUpdates,
          vehiclePositions: state.filteredVehiclePositions,
          alerts: state.filteredAlerts,
          selectedVehicleDescriptor: state.selectedVehicleDescriptor,
          selectedTripDescriptor: state.selectedTripDescriptor,
        );
      },
    );
  }
}

class _CodeViewBody extends StatelessWidget {
  final GTFSData gtfs;
  final List<String> gtfsRealtimeUrls;

  final List<TripUpdate> tripUpdates;
  final List<VehiclePosition> vehiclePositions;
  final List<Alert> alerts;
  final VehicleDescriptor? selectedVehicleDescriptor;
  final TripDescriptor? selectedTripDescriptor;

  const _CodeViewBody({
    required this.gtfsRealtimeUrls,
    required this.tripUpdates,
    required this.vehiclePositions,
    required this.alerts,
    required this.selectedVehicleDescriptor,
    required this.selectedTripDescriptor,
    required this.gtfs,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GTFS Realtime inspector'),
          leading: BlocBuilder<InspectCubit, InspectScreenState>(
            builder: (context, state) {
              if (state.hasAnySelections) {
                return CloseButton(
                  onPressed: () => context.read<InspectCubit>().deselect(),
                );
              } else {
                return const BackButton();
              }
            },
            buildWhen: (p, c) => p.hasAnySelections != c.hasAnySelections,
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Vehicle positions (${vehiclePositions.length})',
              ),
              Tab(
                text: 'Trip updates (${tripUpdates.length})',
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
                    queryParameters: {
                      'gtfs_url': gtfs.url,
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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CodeTab<VehiclePosition>(
                  gtfs: gtfs,
                  entities: vehiclePositions,
                  protoJsonLookup: (e) => e.toProto3Json(),
                  vehicleDescriptorLookup: (e) =>
                      e.hasVehicle() ? e.vehicle : null,
                  tripDescriptorLookup: (e) => e.hasTrip() ? e.trip : null,
                  tooltipMessageLookup: (e) => e.hasTimestamp()
                      ? timestampToFormattedDateTime(e.timestamp.toInt())
                      : null,
                ),
                _CodeTab<TripUpdate>(
                  gtfs: gtfs,
                  entities: tripUpdates,
                  protoJsonLookup: (e) => e.toProto3Json(),
                  vehicleDescriptorLookup: (e) =>
                      e.hasVehicle() ? e.vehicle : null,
                  tripDescriptorLookup: (e) => e.hasTrip() ? e.trip : null,
                  tooltipMessageLookup: (e) => e.hasTimestamp()
                      ? timestampToFormattedDateTime(e.timestamp.toInt())
                      : null,
                ),
                _CodeTab<Alert>(
                  gtfs: gtfs,
                  entities: alerts,
                  protoJsonLookup: (e) => e.toProto3Json(),
                  vehicleDescriptorLookup: (e) => null,
                  tripDescriptorLookup: (e) => null,
                  tooltipMessageLookup: (e) => e.activePeriod.isNotEmpty
                      ? e.activePeriod
                          .map(
                            (p) =>
                                '${timestampToFormattedDateTime(p.start.toInt())} '
                                '- ${timestampToFormattedDateTime(p.end.toInt())}',
                          )
                          .join('\n')
                      : null,
                ),
              ],
            ),
            if (selectedVehicleDescriptor != null ||
                selectedTripDescriptor != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                  child: _builderFilterChip(context),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _builderFilterChip(BuildContext context) {
    final textParts = List<String>.empty(growable: true);

    if (selectedVehicleDescriptor != null) {
      textParts.add(
        'Vehicle: ${selectedVehicleDescriptor?.id.emptyToNull() ?? selectedVehicleDescriptor?.label}',
      );
    }
    if (selectedTripDescriptor != null) {
      textParts.add('Trip: ${selectedTripDescriptor?.tripId}');
    }

    return Chip(
      label: Text(textParts.join(' or ')),
      deleteButtonTooltipMessage: 'Deselect',
      onDeleted: () => context.read<InspectCubit>().deselect(),
    );
  }
}

class _CodeTab<T> extends StatelessWidget {
  final GTFSData gtfs;
  final List<T> entities;
  final Object? Function(T entity) protoJsonLookup;
  final VehicleDescriptor? Function(T entity) vehicleDescriptorLookup;
  final TripDescriptor? Function(T entity) tripDescriptorLookup;
  final String? Function(T entity) tooltipMessageLookup;

  const _CodeTab({
    super.key,
    required this.gtfs,
    required this.entities,
    required this.protoJsonLookup,
    required this.vehicleDescriptorLookup,
    required this.tripDescriptorLookup,
    required this.tooltipMessageLookup,
  });

  @override
  Widget build(BuildContext context) {
    final jsonEncoder = JsonEncoder.withIndent(' ' * 3);

    final theme = MediaQuery.of(context).platformBrightness == Brightness.light
        ? githubTheme
        : darculaTheme;

    return ListView.separated(
      itemCount: entities.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entity = entities[index];
        final json = jsonEncoder.convert(protoJsonLookup(entity));

        final vehicleDescriptor = vehicleDescriptorLookup(entity);
        final tripDescriptor = tripDescriptorLookup(entity);
        final tooltipMessage = tooltipMessageLookup(entity);

        final route =
            tripDescriptor != null ? protoTripToRoute(tripDescriptor) : null;

        final tile = ListTile(
          key: ObjectKey(entity),
          tileColor: theme['root']!.backgroundColor,
          trailing: route != null ? RouteAvatar(route: route) : null,
          onTap: () => vehicleDescriptor != null || tripDescriptor != null
              ? _select(context, vehicleDescriptor, tripDescriptor)
              : null,
          title: HighlightView(
            json,
            language: 'json',
            padding: const EdgeInsets.all(8),
            theme: theme,
          ),
        );

        if (tooltipMessage != null) {
          return Tooltip(
            message: tooltipMessage,
            preferBelow: true,
            child: tile,
          );
        } else {
          return tile;
        }
      },
    );
  }

  void _select(
    BuildContext context,
    VehicleDescriptor? vehicleDescriptor,
    TripDescriptor? tripDescriptor,
  ) {
    context.read<InspectCubit>().select(vehicleDescriptor, tripDescriptor);
  }

  GTFSRoute? protoTripToRoute(TripDescriptor tripDescriptor) {
    if (tripDescriptor.hasRouteId() &&
        gtfs.routesLookup.containsKey(tripDescriptor.routeId)) {
      return gtfs.routesLookup[tripDescriptor.routeId];
    } else if (tripDescriptor.hasTripId()) {
      final routeId = gtfs.tripIdToRouteIdLookup[tripDescriptor.tripId];

      return gtfs.routesLookup[routeId];
    } else {
      return null;
    }
  }
}

class RouteAvatar extends StatelessWidget {
  final GTFSRoute route;

  const RouteAvatar({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final text = route.routeShortName ?? '';

    final routeColor = route.routeColor ?? Colors.indigo;
    final routeTextColor = route.routeTextColor ?? Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: routeColor,
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            style: TextStyle(color: routeTextColor),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
