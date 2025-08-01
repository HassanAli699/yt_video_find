import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:youtube_videos_fetch/data/models/youtube_video.dart';
import '../../../core/utils.dart';

class VideoResultBottomSheet extends StatelessWidget {
    final RxBool usePlaceName;
    final RxString selectedSuggestion;
    final RxString selectedPlaceName;
    final RxList<YouTubeVideo> videos;
    final RxBool hasMore;
    final RxBool isLoadingMore;
    final void Function(ScrollController) onLoadMorePressed;
  const VideoResultBottomSheet({
    super.key, required this.usePlaceName, required this.selectedSuggestion, required this.selectedPlaceName, required this.videos, required this.hasMore, required this.isLoadingMore, required this.onLoadMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        builder: (_, scrollController) {
          return Obx(() => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  usePlaceName.value
                      ? 'Showing videos for "${selectedSuggestion.value} ${selectedPlaceName.value}"'
                      : 'Showing videos near selected location',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: videos.length + (hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == videos.length && hasMore.value) {
                        return Center(
                          child: ElevatedButton.icon(
                            icon: isLoadingMore.value
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.expand_more),
                            label: const Text('Load more'),
                            onPressed: isLoadingMore.value ? null : () => onLoadMorePressed(scrollController),
                          ),
                        );
                      }

                      final video = videos[index];
                      return ListTile(
                        leading: Image.network(video.thumbnail, width: 80, fit: BoxFit.cover),
                        title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.channel),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: video.url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Link copied!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_circle),
                                  onPressed: () => Utils.launchYoutubeApp(video.videoId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ));
        },
      ),
    );
  }
}
