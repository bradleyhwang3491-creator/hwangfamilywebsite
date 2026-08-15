class RoutePoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  RoutePoint({required this.lat, required this.lng, required this.timestamp});

  factory RoutePoint.fromJson(Map<String, dynamic> json) => RoutePoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Maps to the `running_records` table (supabase/migrations/007_create_running_tables.sql).
/// Self-tracked GPS runs — no Health Connect / external source.
class RunningRecord {
  final String id;
  final String userId;
  final String title;
  final DateTime runDate;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  final double? avgSpeedKmh;
  final int? maxHeartRate;
  final List<RoutePoint> route;

  RunningRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.runDate,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    this.avgSpeedKmh,
    this.maxHeartRate,
    this.route = const [],
  });

  factory RunningRecord.fromJson(Map<String, dynamic> json) => RunningRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        runDate: DateTime.parse(json['run_date'] as String),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        durationSeconds: json['duration_seconds'] as int,
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
        maxHeartRate: json['max_heart_rate'] as int?,
        route: (json['route'] as List<dynamic>?)
                ?.map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  double get distanceKm => distanceMeters / 1000;
}
