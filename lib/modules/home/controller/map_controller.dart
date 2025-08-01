import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:youtube_videos_fetch/core/api_service.dart';
import 'package:geolocator/geolocator.dart' as geo_location;
import 'package:youtube_videos_fetch/core/assets.dart';
import 'package:youtube_videos_fetch/data/models/youtube_video.dart';
import 'package:youtube_videos_fetch/modules/home/widget/video_bottom_sheet.dart';

class MapController extends GetxController {
  final Rx<CameraOptions?> initialCamera = Rx<CameraOptions?>(null);
  final Rx<Point?> markerLocation = Rx<Point?>(null);
  final RxBool showFetchButton = false.obs;
  final RxBool isFetchingVideos = false.obs;
  final RxList<YouTubeVideo> videos = <YouTubeVideo>[].obs;
  final RxString selectedPlaceName = ''.obs;
  final RxString? nextPageToken = null;
  final RxBool hasMore = false.obs;
  final RxBool isLoadingMore = false.obs;

  final RxBool usePlaceName = true.obs;
  final RxList<String> searchSuggestions = ['Things to do in', 'Events in', 'Exploring', "Travel vlog in"].obs;
  final RxString selectedSuggestion = 'Things to do in'.obs;

  final TextEditingController newSuggestionController = TextEditingController();

  MapboxMap? mapboxMap;
  PointAnnotationManager? annotationManager;
  PointAnnotation? currentMarker;

  @override
  void onInit() {
    super.onInit();
    _determinePosition();
  }

  @override
  void onClose() {
    newSuggestionController.dispose();
    super.onClose();
  }

  Future<void> _determinePosition() async {
    var permission = await geo_location.Geolocator.checkPermission();
    if (permission == geo_location.LocationPermission.denied) {
      permission = await geo_location.Geolocator.requestPermission();
    }

    final position = await geo_location.Geolocator.getCurrentPosition();
    final point = Point(coordinates: Position(position.longitude, position.latitude));

    markerLocation.value = point;
    initialCamera.value = CameraOptions(center: point, zoom: 14.0);
  }

  Future<Uint8List> loadDefaultMarkerImage() async {
    final byteData = await rootBundle.load(AppAssets.markerPng);
    return byteData.buffer.asUint8List();
  }

  Future<void> addMarkerAtPoint(Point point) async {
    if (currentMarker != null) {
      await annotationManager?.delete(currentMarker!);
    }

    currentMarker = await annotationManager?.create(PointAnnotationOptions(geometry: point, image: await loadDefaultMarkerImage(), iconSize: 0.5));

    selectedPlaceName.value = await ApiService.getPlaceNameFromCoordinates(point.coordinates.lat.toDouble(), point.coordinates.lng.toDouble());

    markerLocation.value = point;
  }

  Future<void> fetchAndShowVideos(BuildContext context) async {
    isFetchingVideos.value = true;

    final lat = markerLocation.value!.coordinates.lat.toDouble();
    final lon = markerLocation.value!.coordinates.lng.toDouble();

    final query = usePlaceName.value ? '${selectedSuggestion.value} ${selectedPlaceName.value}' : '';

    final result = await ApiService.fetchYouTubeVideos(lat: lat, lon: lon, placeName: query);

    videos.assignAll(result.videos);
    nextPageToken?.value = result.nextPageToken ?? "";
    hasMore.value = nextPageToken?.value != null;
    isFetchingVideos.value = false;

    if (videos.isNotEmpty) {
      showVideoBottomSheet();
    } else {
      Get.snackbar(
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          dismissDirection: DismissDirection.horizontal,
          'No videos found.', 'Please try a different location or user a suggestion', duration: Duration(seconds: 2));
    }
  }

  void showVideoBottomSheet() {
    Get.bottomSheet(
      ignoreSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      VideoResultBottomSheet(
        usePlaceName: usePlaceName,
        selectedSuggestion: selectedSuggestion,
        selectedPlaceName: selectedPlaceName,
        videos: videos,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        onLoadMorePressed: loadMoreVideos,
      ),
    );
  }

  Future<void> loadMoreVideos(ScrollController controller) async {
    if (nextPageToken?.value == null || isLoadingMore.value) return;
    isLoadingMore.value = true;

    final lat = markerLocation.value!.coordinates.lat.toDouble();
    final lon = markerLocation.value!.coordinates.lng.toDouble();

    final query = usePlaceName.value ? '${selectedSuggestion.value} ${selectedPlaceName.value}' : '';

    final result = await ApiService.fetchYouTubeVideos(lat: lat, lon: lon, pageToken: nextPageToken?.value, placeName: query);

    videos.addAll(result.videos);
    nextPageToken?.value = result.nextPageToken ?? "";
    hasMore.value = nextPageToken?.value != null;
    isLoadingMore.value = false;
  }
}
