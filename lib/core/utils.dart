import 'package:android_intent_plus/android_intent.dart';

class Utils {


  static void launchYoutubeApp(String videoId) {
    final intent = AndroidIntent(
      action: 'action_view',
      data: 'vnd.youtube:$videoId',
      package: 'com.google.android.youtube',
    );
    intent.launch();
  }

}