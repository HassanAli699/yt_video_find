import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

class VideoListTileWidget extends StatelessWidget {
  final Map<String, dynamic> video;

  const VideoListTileWidget({super.key, required this.video});

  void _launchYoutubeApp(String videoId) {
    final intent = AndroidIntent(
      action: 'action_view',
      data: 'vnd.youtube:$videoId',
      package: 'com.google.android.youtube',
    );
    intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(video['thumbnail'], width: 80, fit: BoxFit.cover),
      title: Text(video['title'], maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(video['channel']),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: video['url']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_circle),
                onPressed: () => _launchYoutubeApp(video['videoId']),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
