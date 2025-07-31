import 'package:flutter/material.dart';

class VideoListPage extends StatelessWidget {
  final List videos;

  const VideoListPage({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Videos')),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          final snippet = video['snippet'];
          final title = snippet['title'];
          final channel = snippet['channelTitle'];
          final thumbnailUrl = snippet['thumbnails']['default']['url'];
          final videoId = video['id']['videoId'];

          return ListTile(
            leading: Image.network(thumbnailUrl),
            title: Text(title),
            subtitle: Text(channel),

            onTap: () {
              final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
              // You can launch this URL with url_launcher if you want
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video URL: $videoUrl')),
              );
            },
          );
        },
      ),
    );
  }
}
