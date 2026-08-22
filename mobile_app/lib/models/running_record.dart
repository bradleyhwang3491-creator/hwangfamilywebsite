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
  final int? avgPaceSeconds;
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
    this.avgPaceSeconds,
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
        avgPaceSeconds: (json['avg_pace_seconds'] as num?)?.round(),
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

  /// 저장된 평균 페이스를 우선 쓰고, 없으면(옛 기록) 거리/시간으로 계산한다.
  String? get paceLabel => avgPaceSeconds != null
      ? formatPaceSeconds(avgPaceSeconds!)
      : computePace(distanceMeters, durationSeconds);

  String get durationLabel => formatDuration(durationSeconds);

  /// 거리/시간에서 km당 페이스(초)를 계산. 둘 중 하나라도 0이면 null.
  static int? computePaceSeconds(double distanceMeters, int durationSeconds) {
    final km = distanceMeters / 1000;
    if (km <= 0 || durationSeconds <= 0) return null;
    return (durationSeconds / km).round();
  }

  static String? computePace(double distanceMeters, int durationSeconds) {
    final seconds = computePaceSeconds(distanceMeters, durationSeconds);
    return seconds == null ? null : formatPaceSeconds(seconds);
  }

  /// "5'30\"" 형태로 표시.
  static String formatPaceSeconds(int secondsPerKm) {
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// 입력창용 "5:30" 형태.
  static String formatPaceInput(int secondsPerKm) {
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// "5:30" / "5'30\"" / "5" 를 km당 초로 파싱. 형식이 틀리면 null.
  static int? parsePaceInput(String raw) {
    final text = raw.replaceAll(RegExp(r'''["']'''), ':').replaceAll(RegExp(r':+$'), '').trim();
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length > 2) return null;
    final minutes = int.tryParse(parts[0].trim());
    if (minutes == null) return null;
    if (parts.length == 1) return minutes * 60;
    final seconds = int.tryParse(parts[1].trim());
    if (seconds == null || seconds >= 60) return null;
    return minutes * 60 + seconds;
  }

  /// "MM:SS" / "H:MM:SS" / "45"(분) 을 초로 파싱. 형식이 틀리면 null.
  static int? parseDurationInput(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length > 3) return null;
    final numbers = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value == null) return null;
      numbers.add(value);
    }
    if (numbers.length == 1) return numbers[0] * 60; // 숫자만 적으면 분으로 해석
    if (numbers.length == 2) return numbers[0] * 60 + numbers[1];
    return numbers[0] * 3600 + numbers[1] * 60 + numbers[2];
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
