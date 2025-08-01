import 'package:flutter/material.dart';
import 'package:youtube_videos_fetch/modules/home/view/map_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MapPage(); /// PASSING IN THROUGH HOME PAGE BECAUSE IN FUTURE WE CAN ADD MORE
                      /// PAGES OR MORE OPTION
  }
}
