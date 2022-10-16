import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gtfs_realtime_inspector/utils.dart';

class FeedInputScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

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
      gtfsUrl: 'https://gtfs.ovapi.nl/nl/gtfs-nl.zip',
      gtfsRealtimeUrls: [
        'https://gtfs.ovapi.nl/nl/tripUpdates.pb',
        'https://gtfs.ovapi.nl/nl/vehiclePositions.pb',
        'https://gtfs.ovapi.nl/nl/alerts.pb',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GTFS Realtime inspector'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    const _UrlInputField(
                      labelText: 'GTFS URL',
                      hintText: 'https://example.com/gtfs.zip',
                      isRequired: true,
                    ),
                    const _UrlInputField(
                      labelText: 'GTFS REALTIME URL',
                      hintText: 'https://example.com/trip_updates.pb',
                      isRequired: true,
                    ),
                    const _UrlInputField(
                      labelText: 'GTFS REALTIME URL',
                      hintText: 'https://example.com/vehicle_positions.pb',
                      isRequired: false,
                    ),
                    const _UrlInputField(
                      labelText: 'GTFS REALTIME URL',
                      hintText: 'https://example.com/service_alerts.pb',
                      isRequired: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Processing Data')),
                            );
                          }
                        },
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
                                vertical: 8.0,
                                horizontal: 4,
                              ),
                              child: ActionChip(
                                label: Text(feed.key),
                                tooltip: 'Inspect ${feed.key}',
                                onPressed: () {
                                  _inspectFeeds(
                                    context,
                                    feed.value.gtfsUrl,
                                    feed.value.gtfsRealtimeUrls,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inspectFeeds(
    BuildContext context,
    String gtfsUrl,
    List<String> gtfsRealtimeUrls,
  ) {
    context.go(
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
  final String labelText;
  final String hintText;
  final bool isRequired;

  const _UrlInputField({
    required this.labelText,
    required this.hintText,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: isRequired ? 'Required' : null,
        ),
        keyboardType: TextInputType.url,
        validator: (value) {
          if (!isRequired && (value == null || value.isEmpty)) {
            return null;
          } else if (value == null || value.isEmpty) {
            return 'Please enter URL';
          } else if (isValidUrl(value)) {
            return 'Please enter valid URL';
          } else {
            return null;
          }
        },
      ),
    );
  }
}

class FeedsInput {
  final String gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  FeedsInput({
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });
}
