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
  final int? avgHeartRate;
  final int? maxHeartRate;
  final double? caloriesBurned;
  final String? photoPath;
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
    this.avgHeartRate,
    this.maxHeartRate,
    this.caloriesBurned,
    this.photoPath,
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
        avgHeartRate: json['avg_heart_rate'] as int?,
        maxHeartRate: json['max_heart_rate'] as int?,
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        photoPath: json['photo_path'] as String?,
        route: (json['route'] as List<dynamic>?)
                ?.map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  double get distanceKm => distanceMeters / 1000;

  /// 평균 페이스 — 거리와 시간에서 계산한다(별도 컬럼 없음).
  String? get paceLabel => formatPace(distanceMeters, durationSeconds);

  String get durationLabel => formatDuration(durationSeconds);

  /// "5'30\"" 형태의 km당 페이스. 거리/시간이 0이면 null.
  static String? formatPace(double distanceMeters, int durationSeconds) {
    final km = distanceMeters / 1000;
    if (km <= 0 || durationSeconds <= 0) return null;
    final secondsPerKm = durationSeconds / km;
    var minutes = secondsPerKm ~/ 60;
    var seconds = (secondsPerKm % 60).round();
    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
    }
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// 1시간 미만이면 "MM:SS", 넘으면 "H:MM:SS".
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }
}
