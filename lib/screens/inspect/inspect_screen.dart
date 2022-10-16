import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/code_view.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/transit_service.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/vehicles_map.dart';
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
      body: _TransitDataFutureBuilder(
        future: TransitService().fetchTransitFeeds(gtfsUrl, gtfsRealtimeUrls),
        builder: (context, data) {
          return _InspectScreenBody(data: data);
        },
      ),
    );
  }
}

class _InspectScreenBody extends StatelessWidget {
  final TransitData data;

  const _InspectScreenBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final state = InspectScreenState(
          gtfs: data.gtfs,
          allTripUpdates: data.realtime.tripUpdates,
          allVehiclePositions: data.realtime.vehiclePositions,
          allAlerts: data.realtime.alerts,
          filteredTripUpdates: data.realtime.tripUpdates,
          filteredVehiclePositions: data.realtime.vehiclePositions,
          filteredAlerts: data.realtime.alerts,
        );
        return InspectCubit(state);
      },
      child: SplitView(
        viewMode: SplitViewMode.Horizontal,
        indicator: const SplitIndicator(
          viewMode: SplitViewMode.Horizontal,
        ),
        controller: SplitViewController(
          weights: [0.4, 0.6],
        ),
        children: [
          CodeView(),
          VehiclesMap(
            vehiclePositions: data.realtime.vehiclePositions,
            tripIdToRouteIdLookup: data.gtfs.tripIdToRouteIdLookup,
            routesLookup: data.gtfs.routesLookup,
          ),
        ],
      ),
    );
  }
}

class _TransitDataFutureBuilder extends StatelessWidget {
  final Future<TransitData> future;
  final Widget Function(BuildContext context, TransitData data) builder;

  const _TransitDataFutureBuilder({
    required this.future,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransitData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return builder(context, snapshot.requireData);
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Error: ${snapshot.error}\n${snapshot.stackTrace}',
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Fetching GTFS and GTFS Realtime transit feeds. It might take long time...',
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
