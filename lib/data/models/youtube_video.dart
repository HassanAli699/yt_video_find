class YouTubeVideo {
  final String title;
  final String channel;
  final String videoId;
  final String thumbnail;
  final String url;

  YouTubeVideo({
    required this.title,
    required this.channel,
    required this.videoId,
    required this.thumbnail,
  }) : url = 'https://www.youtube.com/watch?v=$videoId';

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final videoId = json['id']['videoId'];

    return YouTubeVideo(
      title: snippet['title'],
      channel: snippet['channelTitle'],
      videoId: videoId,
      thumbnail: snippet['thumbnails']['default']['url'],
    );
  }
}
