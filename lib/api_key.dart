import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;



Future<Map<String, dynamic>> fetchYouTubeVideos({
  required double lat,
  required double lon,
  int maxResults = 30,
  String? pageToken,
  required String placeName,
}) async {


  final uri = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search'
        '?key=${dotenv.env['YTAPIKEY']!}'
        '&part=snippet'
        '&type=video'
        '&location=$lat,$lon'
        '&q=${Uri.encodeComponent(placeName)}'
        '&locationRadius=15mi'
        '&maxResults=$maxResults'
        '&order=date'
        '${pageToken != null ? '&pageToken=$pageToken' : ''}',
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data);
    final videos = (data['items'] as List).map((item) {
      final videoId = item['id']['videoId'];
      return {
        'title': item['snippet']['title'],
        'channel': item['snippet']['channelTitle'],
        'videoId': videoId,
        'thumbnail': item['snippet']['thumbnails']['default']['url'],
        'url': 'https://www.youtube.com/watch?v=$videoId',
      };
    }).toList();

    return {
      'totalResults': data['pageInfo']['totalResults'],
      'videos': videos,
      'nextPageToken': data['nextPageToken'],
    };
  } else {
    throw Exception('Failed to load YouTube videos');
  }
}


Future<String> getPlaceNameFromCoordinates(double lat, double lng) async {



  final url = Uri.parse(
    'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
        '?access_token=${dotenv.env['MAPBOXAPIKEY']!}&types=place,locality,neighborhood,address',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'];
      if (features != null && features.isNotEmpty) {
        print(features[0]['place_name']);
        return features[0]['place_name'];
      }
    } else {
      debugPrint('Failed to fetch place name: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching place name: $e');
  }

  return "";
}
