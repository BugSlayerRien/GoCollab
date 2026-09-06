import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A single geocoded place result from a place search.
class PlaceSuggestion {
  const PlaceSuggestion({required this.displayName, required this.latitude, required this.longitude});

  final String displayName;
  final double latitude;
  final double longitude;
}

/// Free-text place search backed by OpenStreetMap's Nominatim API — no API
/// key required, consistent with the rest of the app's map stack
/// (`flutter_map` + OSM tiles, no Google Maps SDK).
///
/// Lets an officer type a venue name/address and pick a result instead of
/// copying latitude/longitude by hand. Respects Nominatim's usage policy: a
/// descriptive User-Agent and callers are expected to debounce requests
/// (the search field in `create_event_sheet.dart` debounces ~500ms).
class PlaceSearchService {
  PlaceSearchService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _userAgent = 'GoCollab/1.0 (ph.gdgoc.gocollab.gocollab)';

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '5',
      'addressdetails': '0',
    });

    late final http.Response response;
    try {
      response = await _http.get(uri, headers: const {'User-Agent': _userAgent}).timeout(const Duration(seconds: 10));
    } catch (_) {
      return [];
    }

    if (response.statusCode != 200) return [];

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final lat = double.tryParse(row['lat']?.toString() ?? '');
            final lon = double.tryParse(row['lon']?.toString() ?? '');
            final name = row['display_name'] as String?;
            if (lat == null || lon == null || name == null) return null;
            return PlaceSuggestion(displayName: name, latitude: lat, longitude: lon);
          })
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
