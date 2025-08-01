import 'youtube_video.dart';

class YouTubeSearchResponse {
  final List<YouTubeVideo> videos;
  final String? nextPageToken;
  final int totalResults;

  YouTubeSearchResponse({
    required this.videos,
    required this.totalResults,
    this.nextPageToken,
  });

  factory YouTubeSearchResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((item) => YouTubeVideo.fromJson(item))
        .toList();

    return YouTubeSearchResponse(
      videos: items,
      totalResults: json['pageInfo']['totalResults'],
      nextPageToken: json['nextPageToken'],
    );
  }
}
