import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/models/place_result.dart';
import '../data/models/youtube_search_response.dart';


class ApiService {
  static const _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const _youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3/search';
  static const _mapboxBaseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

  static Future<List<PlaceResult>> searchPlaces(String term) async {
    final uri = Uri.parse(
      '$_nominatimBaseUrl/search?q=$term&format=json&limit=5&addressdetails=1&accept-language=en',
    );

    try {
      final response = await http.get(uri, headers: {'User-Agent': 'MapApp/1.0'});

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((e) => PlaceResult.fromJson(e)).toList();
      } else {
        debugPrint('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in searchPlaces: $e');
    }

    return [];
  }

  static Future<YouTubeSearchResponse> fetchYouTubeVideos({
    required double lat,
    required double lon,
    required String placeName,
    int maxResults = 30,
    String? pageToken,
  }) async {
    final apiKey = dotenv.env['YT_APIKEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('YouTube API key is missing.');
    }

    final uri = Uri.parse(
      '$_youtubeBaseUrl'
          '?key=$apiKey'
          '&part=snippet'
          '&type=video'
          '&location=$lat,$lon'
          '&locationRadius=15mi'
          '&maxResults=$maxResults'
          '&order=date'
          '&q=${Uri.encodeComponent(placeName)}'
          '${pageToken != null ? '&pageToken=$pageToken' : ''}',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return YouTubeSearchResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load YouTube videos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchYouTubeVideos: $e');
      rethrow;
    }
  }

  static Future<String> getPlaceNameFromCoordinates(double lat, double lng) async {
    final accessToken = dotenv.env['MAPBOX_APIKEY'];
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Mapbox API key is missing.');
    }

    final uri = Uri.parse(
      '$_mapboxBaseUrl/$lng,$lat.json?access_token=$accessToken&types=place,locality,neighborhood,address',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'];

        if (features != null && features.isNotEmpty) {
          final placeName = features[0]['place_name'];
          debugPrint('Resolved place name: $placeName');
          return placeName;
        }
      } else {
        debugPrint('Failed to fetch place name: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getPlaceNameFromCoordinates: $e');
    }

    return '';
  }
}
