import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gtfs_realtime_inspector/screens/input/feeds_input_bloc.dart';

class FeedsInputScreen extends StatelessWidget {
  final String? initialGtfsUrl;
  final List<String> initialGtfsRealtimeUrls;

  final _exampleFeeds = {
    'Vilnius, Lithuania': FeedsInput(
      gtfsUrl: 'https://stops.lt/vilnius/vilnius/gtfs.zip',
      gtfsRealtimeUrls: [
        'https://www.stops.lt/vilnius/trip_updates.pb',
        'https://www.stops.lt/vilnius/vehicle_positions.pb',
        'https://www.stops.lt/vilnius/service_alerts.pb',
      ],
    ),
    'Kaunas, Lithuania': FeedsInput(
      gtfsUrl: 'https://stops.lt/kaunas/kaunas/gtfs.zip',
      gtfsRealtimeUrls: [
        'https://www.stops.lt/kaunas/trip_updates.pb',
        'https://www.stops.lt/kaunas/vehicle_positions.pb',
        'https://www.stops.lt/kaunas/service_alerts.pb',
      ],
    ),
    'Klaipėda, Lithuania': FeedsInput(
      gtfsUrl: 'https://www.stops.lt/klaipeda/klaipeda/gtfs.zip',
      gtfsRealtimeUrls: [
        'https://www.stops.lt/klaipeda/gtfs_realtime.pb',
      ],
    ),
    'Panevėžys, Lithuania': FeedsInput(
      gtfsUrl: 'https://www.stops.lt/panevezys/panevezys/gtfs.zip',
      gtfsRealtimeUrls: [
        'https://www.stops.lt/panevezys/gtfs_realtime.pb',
      ],
    ),
    'Netherlands': FeedsInput(
      gtfsUrl: null,
      gtfsRealtimeUrls: [
        'https://gtfs.ovapi.nl/nl/tripUpdates.pb',
        'https://gtfs.ovapi.nl/nl/vehiclePositions.pb',
        'https://gtfs.ovapi.nl/nl/alerts.pb',
      ],
    ),
    'Norway': FeedsInput(
      gtfsUrl:
          'https://storage.googleapis.com/marduk-production/outbound/gtfs/rb_norway-aggregated-gtfs-basic.zip',
      gtfsRealtimeUrls: [
        'https://api.entur.io/realtime/v1/gtfs-rt/trip-updates',
        'https://api.entur.io/realtime/v1/gtfs-rt/vehicle-positions',
        'https://api.entur.io/realtime/v1/gtfs-rt/alerts',
      ],
    ),
  };

  FeedsInputScreen({
    super.key,
    required this.initialGtfsUrl,
    required this.initialGtfsRealtimeUrls,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeedsInputBloc(
        initialGtfsUrl: initialGtfsUrl,
        initialGtfsRealtimeUrls: initialGtfsRealtimeUrls,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GTFS Realtime inspector'),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Builder(
              builder: (context) {
                final formBloc = BlocProvider.of<FeedsInputBloc>(context);
                return FormBlocListener<FeedsInputBloc, FeedsInput, String>(
                  formBloc: formBloc,
                  onSuccess: (context, state) {
                    final feedsInput = state.successResponse!;

                    _inspectFeeds(
                      context,
                      feedsInput.gtfsUrl,
                      feedsInput.gtfsRealtimeUrls,
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _UrlInputField(
                        bloc: formBloc.gtfsUrl,
                        labelText: 'GTFS URL',
                        hintText: 'https://example.com/gtfs.zip',
                        helperText:
                            'If GTFS provided, additional information will be shown',
                      ),
                      _UrlInputField(
                        bloc: formBloc.gtfsRealtime1Url,
                        labelText: 'GTFS REALTIME URL',
                        hintText: 'https://example.com/trip_updates.pb',
                        helperText:
                            'At least one GTFS Realtime feed must be provided',
                      ),
                      _UrlInputField(
                        bloc: formBloc.gtfsRealtime2Url,
                        labelText: 'GTFS REALTIME URL',
                        hintText: 'https://example.com/vehicle_positions.pb',
                      ),
                      _UrlInputField(
                        bloc: formBloc.gtfsRealtime3Url,
                        labelText: 'GTFS REALTIME URL',
                        hintText: 'https://example.com/service_alerts.pb',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          onPressed: formBloc.submit,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Inspect'),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            for (final feed in _exampleFeeds.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                child: ActionChip(
                                  label: Text(feed.key),
                                  onPressed: () {
                                    final feedInput = feed.value;

                                    formBloc.updateValues(
                                      feedInput.gtfsUrl,
                                      feedInput.gtfsRealtimeUrls,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _inspectFeeds(
    BuildContext context,
    String? gtfsUrl,
    List<String> gtfsRealtimeUrls,
  ) {
    context.push(
      context.namedLocation(
        'inspect',
        queryParams: {
          'gtfs_url': gtfsUrl,
          'gtfs_realtime_urls': gtfsRealtimeUrls,
        },
      ),
    );
  }
}

class _UrlInputField extends StatelessWidget {
  final TextFieldBloc bloc;
  final String labelText;
  final String hintText;
  final String? helperText;

  const _UrlInputField({
    required this.bloc,
    required this.labelText,
    required this.hintText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldBlocBuilder(
      textFieldBloc: bloc,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
      ),
      keyboardType: TextInputType.url,
    );
  }
}

class FeedsInput {
  final String? gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  FeedsInput({
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });
}
