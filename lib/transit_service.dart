import 'dart:convert';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;

class TransitService {
  Future<TransitData> fetchTransitFeeds(
    String gtfsUrl,
    List<String> gtfsRealtimeUrls,
  ) async {
    final gtfsData = await _fetchGTFSFromUrl(gtfsUrl);
    final gtfsRealtimeData = await _fetchGtfRealtimeData(gtfsRealtimeUrls);

    return TransitData(gtfs: gtfsData, realtime: gtfsRealtimeData);
  }

  Future<FeedMessage> _fetchGtfRealtimeFeed(String gtfsRealtimeUrl) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url =
        'https://api.allorigins.win/raw?url=$gtfsRealtimeUrl?time=$timestamp';
    final response = await http.get(Uri.parse(url));
    final message = FeedMessage.fromBuffer(response.bodyBytes);

    return message;
  }

  Future<GTFSRealtimeData> _fetchGtfRealtimeData(
    List<String> gtfsRealtimeUrls,
  ) async {
    final feeds = await Future.wait(
      gtfsRealtimeUrls.map((u) => _fetchGtfRealtimeFeed(u)),
    );

    final initialData = GTFSRealtimeData(
      tripUpdates: List.empty(growable: true),
      vehiclePositions: List.empty(growable: true),
      alerts: List.empty(growable: true),
    );

    return feeds.fold<GTFSRealtimeData>(initialData, (rt, feed) {
      final entity = feed.entity;

      final tripUpdates =
          entity.where((e) => e.hasTripUpdate()).map((e) => e.tripUpdate);
      final vehiclePositions =
          entity.where((e) => e.hasVehicle()).map((e) => e.vehicle);
      final alerts = entity.where((e) => e.hasAlert()).map((e) => e.alert);

      return GTFSRealtimeData(
        tripUpdates: rt.tripUpdates..addAll(tripUpdates),
        vehiclePositions: rt.vehiclePositions..addAll(vehiclePositions),
        alerts: rt.alerts..addAll(alerts),
      );
    });
  }

  Future<GTFSData> _fetchGTFSFromUrl(String gtfsUrl) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final url = 'https://api.allorigins.win/raw?url=$gtfsUrl?time=$timestamp';

    final response = await http.get(Uri.parse(url));

    final archive = ZipDecoder().decodeBytes(
      response.bodyBytes,
      verify: true,
    );

    final tripIdToRouteIdLookup = _buildTripIdToRouteIdLookup(archive);
    final routesLookup = _buildRoutesLookup(archive);

    return GTFSData(
      tripIdToRouteIdLookup: tripIdToRouteIdLookup,
      routesLookup: routesLookup,
    );
  }

  Map<String, String> _buildTripIdToRouteIdLookup(Archive archive) {
    final tripIdToRouteIdEntries = _mapFileRowsToInserts(
      archive,
      'trips.txt',
      (rowValues) {
        final tripId = rowValues.getRequiredValue<String>('trip_id');
        final routeId = rowValues.getRequiredValue<String>('route_id');

        return MapEntry(tripId, routeId);
      },
    );

    return Map<String, String>.fromEntries(tripIdToRouteIdEntries);
  }

  Map<String, GTFSRoute> _buildRoutesLookup(Archive archive) {
    final routesLookupEntries = _mapFileRowsToInserts(
      archive,
      'routes.txt',
      (rowValues) {
        final route = GTFSRoute(
          routeId: rowValues.getRequiredValue('route_id'),
          routeShortName: rowValues.getValue('route_short_name'),
          routeLongName: rowValues.getValue('route_long_name'),
          routeColor: rowValues.getValue('route_color'),
          routeTextColor: rowValues.getValue('route_text_color'),
        );

        return MapEntry(route.routeId, route);
      },
    );

    return Map<String, GTFSRoute>.fromEntries(routesLookupEntries);
  }

  Iterable<T> _mapFileRowsToInserts<T>(
    Archive archive,
    String fileName,
    T Function(_CsvRowValues rowValues) insertMapper, {
    bool isRequired = true,
  }) {
    final file = archive.findFile(fileName);

    if (file == null) {
      if (isRequired) {
        throw ArgumentError.notNull('$fileName is required in GTFS file');
      } else {
        return [];
      }
    }

    final bytes = file.content as List<int>;
    final data = utf8.decode(bytes);

    final rowsAsListOfValues =
        const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
            .convert(data)
            .map((l) => List<String>.from(l));

    final Map<String, int> headerIndexLookup = rowsAsListOfValues.first
        .asMap()
        .map((key, value) => MapEntry(value, key));

    return rowsAsListOfValues.skip(1).map(
      (r) {
        final rowValues = _CsvRowValues(
          headerIndexLookup: headerIndexLookup,
          row: r,
        );

        return insertMapper(rowValues);
      },
    );
  }
}

class _CsvRowValues {
  final Map<String, int> headerIndexLookup;
  final List<String> row;

  _CsvRowValues({required this.headerIndexLookup, required this.row});

  T _parseValue<T>(String value) {
    switch (T) {
      case String:
        return value as T;
      case int:
        return int.parse(value) as T;
      case double:
        return double.parse(value) as T;
      case bool:
        return (value == '1') as T;
    }

    throw ArgumentError.value(
      value,
      'Unable to map to type $T',
    );
  }

  T getRequiredValue<T>(String name) {
    final index = headerIndexLookup[name];
    if (index == null) {
      throw ArgumentError.notNull(name);
    }

    final value = row[index];
    if (value.trim() == '') {
      throw ArgumentError.value(
        value,
        '$name can not be empty, because it is required',
      );
    }

    return _parseValue<T>(value);
  }

  T? getValue<T>(String name) {
    final index = headerIndexLookup[name];
    if (index == null) {
      return null;
    }

    final value = row[index];
    if (value.trim() == '') {
      return null;
    }

    return _parseValue<T>(value);
  }
}

class TransitData {
  final GTFSData gtfs;
  final GTFSRealtimeData realtime;

  TransitData({required this.gtfs, required this.realtime});
}

class GTFSData {
  final Map<String, GTFSRoute> routesLookup;
  final Map<String, String> tripIdToRouteIdLookup;

  const GTFSData({
    required this.tripIdToRouteIdLookup,
    required this.routesLookup,
  });
}

class GTFSRoute {
  final String routeId;
  final String? routeShortName;
  final String? routeLongName;
  final String? routeColor;
  final String? routeTextColor;

  GTFSRoute({
    required this.routeId,
    this.routeShortName,
    this.routeLongName,
    this.routeColor,
    this.routeTextColor,
  });

  Color _hexToColor(String hexString) {
    var hexColor = hexString;
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }

    throw Exception('Unable to pass color $hexString');
  }

  Color? get parsedRouteColor {
    if (routeColor != null) {
      return _hexToColor(routeColor!);
    }

    return null;
  }

  Color? get parsedRouteTextColor {
    if (routeTextColor != null) {
      return _hexToColor(routeTextColor!);
    }

    return null;
  }
}

class GTFSRealtimeData {
  final List<TripUpdate> tripUpdates;
  final List<VehiclePosition> vehiclePositions;
  final List<Alert> alerts;

  const GTFSRealtimeData({
    required this.tripUpdates,
    required this.vehiclePositions,
    required this.alerts,
  });
}
