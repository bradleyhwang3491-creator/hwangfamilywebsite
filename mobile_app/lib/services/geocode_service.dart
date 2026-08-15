import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodeResult {
  final double lat;
  final double lng;
  final String? country;
  final bool isDomestic;

  GeocodeResult({
    required this.lat,
    required this.lng,
    required this.country,
    required this.isDomestic,
  });
}

/// Ported from src/lib/geocode.ts — same Nominatim (OpenStreetMap) endpoint.
class GeocodeService {
  static const _domesticCountryNames = {'대한민국', 'South Korea', 'Republic of Korea'};

  static Future<GeocodeResult?> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json&addressdetails=1&limit=1&accept-language=ko'
      '&q=${Uri.encodeQueryComponent(address)}',
    );
    final res = await http.get(url, headers: {'User-Agent': 'hwang-family-app'});
    if (res.statusCode != 200) return null;

    final results = jsonDecode(res.body) as List<dynamic>;
    if (results.isEmpty) return null;
    final hit = results.first as Map<String, dynamic>;

    final address_ = hit['address'] as Map<String, dynamic>?;
    final country = address_?['country'] as String?;

    return GeocodeResult(
      lat: double.parse(hit['lat'] as String),
      lng: double.parse(hit['lon'] as String),
      country: country,
      isDomestic: country != null && _domesticCountryNames.contains(country),
    );
  }
}
