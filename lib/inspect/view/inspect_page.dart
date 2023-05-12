import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_inspector/inspect/cubit/inspect_cubit.dart';
import 'package:gtfs_realtime_inspector/inspect/models/models.dart';
import 'package:gtfs_realtime_inspector/inspect/service/transit_service.dart';
import 'package:gtfs_realtime_inspector/inspect/view/code_view.dart';
import 'package:gtfs_realtime_inspector/inspect/view/sync_selector_view.dart';
import 'package:gtfs_realtime_inspector/inspect/view/vehicles_map.dart';
import 'package:gtfs_realtime_inspector/utils.dart';
import 'package:split_view/split_view.dart';

class InspectPage extends StatefulWidget {
  final String? gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  const InspectPage({
    super.key,
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });

  @override
  State<InspectPage> createState() => _InspectPageState();
}

class _InspectPageState extends State<InspectPage> {
  final _transitDataMemo = AsyncMemoizer<TransitData>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _TransitDataFutureBuilder(
        future: _transitDataMemo.runOnce(
          () => _fetchTransitFeeds(),
        ),
        builder: (context, data) {
          return _InspectScreenBody(data: data);
        },
      ),
    );
  }

  Future<TransitData> _fetchTransitFeeds() {
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
          Stack(
            children: [
              VehiclesMap(
                center: getNearestLatLngToVehiclePositionsCenter(
                  widget.data.realtime.vehiclePositions,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SyncSelectorView(),
                ),
              ),
            ],
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

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Fetching transit feeds. It might take a long time...',
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
