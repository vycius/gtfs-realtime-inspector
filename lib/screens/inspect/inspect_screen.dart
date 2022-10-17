import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/code_view.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/transit_service.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/vehicles_map.dart';
import 'package:split_view/split_view.dart';

class InspectScreen extends StatefulWidget {
  final String? gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  const InspectScreen({
    super.key,
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });

  @override
  State<InspectScreen> createState() => _InspectScreenState();
}

class _InspectScreenState extends State<InspectScreen> {
  final _transitDataMemo = AsyncMemoizer<TransitData>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _TransitDataFutureBuilder(
        future: _transitDataMemo.runOnce(
          () => compute(
            _fetchTransitFeeds,
            '',
          ),
        ),
        builder: (context, data) {
          return _InspectScreenBody(data: data);
        },
      ),
    );
  }

  Future<TransitData> _fetchTransitFeeds(String s) {
    return TransitService().fetchTransitFeeds(
      widget.gtfsUrl,
      widget.gtfsRealtimeUrls,
    );
  }
}

class _InspectScreenBody extends StatefulWidget {
  final TransitData data;

  const _InspectScreenBody({required this.data});

  @override
  State<_InspectScreenBody> createState() => _InspectScreenBodyState();
}

class _InspectScreenBodyState extends State<_InspectScreenBody> {
  @override
  void initState() {
    super.initState();

    final warning = widget.data.gtfs.warning;
    if (warning != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final state = InspectScreenState(
          gtfsRealtimeUrls: widget.data.gtfsRealtimeUrls,
          gtfs: widget.data.gtfs,
          allTripUpdates: widget.data.realtime.tripUpdates,
          allVehiclePositions: widget.data.realtime.vehiclePositions,
          allAlerts: widget.data.realtime.alerts,
          filteredTripUpdates: widget.data.realtime.tripUpdates,
          filteredVehiclePositions: widget.data.realtime.vehiclePositions,
          filteredAlerts: widget.data.realtime.alerts,
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
            vehiclePositions: widget.data.realtime.vehiclePositions,
            tripIdToRouteIdLookup: widget.data.gtfs.tripIdToRouteIdLookup,
            routesLookup: widget.data.gtfs.routesLookup,
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
                  'Fetching GTFS and GTFS Realtime transit feeds. It might take a long time...',
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
