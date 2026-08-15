class TravelRecord {
  final String id;
  final String userId;
  final String title;
  final String region;
  final String address;
  final String? country;
  final double? lat;
  final double? lng;
  final bool? isDomestic;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final String content;
  final DateTime createdAt;

  TravelRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.region,
    required this.address,
    required this.country,
    required this.lat,
    required this.lng,
    required this.isDomestic,
    required this.startDate,
    required this.endDate,
    required this.content,
    required this.createdAt,
  });

  factory TravelRecord.fromJson(Map<String, dynamic> json) => TravelRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        region: json['region'] as String,
        address: json['address'] as String,
        country: json['country'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        isDomestic: json['is_domestic'] as bool?,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      );

  int get days {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return end.difference(start).inDays + 1;
  }
}
