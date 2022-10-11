import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;

class GTFSRealtimeService {
  Future<FeedMessage> _fetchGtfRealtimeFeed(String gtfsRealtimeUrl) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url =
        'https://api.allorigins.win/raw?url=$gtfsRealtimeUrl?time=$timestamp';
    final response = await http.get(Uri.parse(url));
    final message = FeedMessage.fromBuffer(response.bodyBytes);

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
