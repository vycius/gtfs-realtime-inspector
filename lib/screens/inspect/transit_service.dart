import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:gtfs_realtime_inspector/screens/inspect/models.dart';
import 'package:gtfs_realtime_inspector/utils.dart';
import 'package:http/http.dart' as http;

class TransitService {
  Future<TransitData> fetchTransitFeeds(
    String? gtfsUrl,
    List<String> gtfsRealtimeUrls,
  ) async {
    final gtfsData = await _fetchGTFSFromUrl(gtfsUrl);
    final gtfsRealtimeData = await fetchGtfRealtimeData(gtfsRealtimeUrls);

    return TransitData(
      gtfsRealtimeUrls: gtfsRealtimeUrls,
      gtfs: gtfsData,
      realtime: gtfsRealtimeData,
    );
  }

  Future<Uint8List> _getBytesThroughCorsProxy(String url) {
    final uri = Uri.parse('https://cors-proxy.vycius.lt/?$url');

    return http.readBytes(uri);
  }

  Future<FeedMessage> _fetchGtfRealtimeFeed(String gtfsRealtimeUrl) async {
    final bytes = await _getBytesThroughCorsProxy(gtfsRealtimeUrl);
    final message = FeedMessage.fromBuffer(bytes);

    return message;
  }

  Future<GTFSRealtimeData> fetchGtfRealtimeData(
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

  Future<GTFSData> _fetchGTFSFromUrl(String? gtfsUrl) async {
    if (gtfsUrl == null) {
      return GTFSData(
        url: gtfsUrl,
        tripIdToRouteIdLookup: {},
        routesLookup: {},
      );
    } else {
      try {
        final bytes = await _getBytesThroughCorsProxy(gtfsUrl);

        final decompressed = await compute(
          ZipDecoder().decodeBytes,
          bytes,
        );

        final tripIdToRouteIdLookup = _buildTripIdToRouteIdLookup(decompressed);
        final routesLookup = _buildRoutesLookup(decompressed);

        return GTFSData(
          url: gtfsUrl,
          tripIdToRouteIdLookup: tripIdToRouteIdLookup,
          routesLookup: routesLookup,
        );
      } on Exception catch (ex) {
        return GTFSData(
          url: gtfsUrl,
          tripIdToRouteIdLookup: {},
          routesLookup: {},
          warning: 'Unable to load GTFS: $ex',
        );
      }
    }
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
        final routeColorCode = rowValues.getValue<String>('route_color');
        final routeTextColorCode = rowValues.getValue<String>(
          'route_text_color',
        );

        final route = GTFSRoute(
          routeId: rowValues.getRequiredValue('route_id'),
          routeShortName: rowValues.getValue('route_short_name'),
          routeColor:
              routeColorCode != null ? hexToColor(routeColorCode) : null,
          routeTextColor: routeTextColorCode != null
              ? hexToColor(routeTextColorCode)
              : null,
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
