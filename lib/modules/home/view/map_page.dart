import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:youtube_videos_fetch/core/api_service.dart';
import 'package:youtube_videos_fetch/modules/home/widget/drawer.dart';
import 'package:youtube_videos_fetch/modules/home/widget/floating_fetch_button.dart';
import 'package:youtube_videos_fetch/modules/home/widget/search_delegate.dart';
import '../controller/map_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController controller = Get.put(MapController());
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Obx(() {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(CupertinoIcons.list_bullet_indent),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            title: const Text('YT Video Find', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.search),
                onPressed: () async {
                  final result = await showSearch<Point?>(
                    context: context,
                    delegate: PlaceSearchDelegate(
                      currentLocation:
                          controller.markerLocation.value != null
                              ? LatLng(controller.markerLocation.value!.coordinates.lat.toDouble(), controller.markerLocation.value!.coordinates.lng.toDouble())
                              : null,
                    ),
                  );
                  if (result != null && controller.mapboxMap != null && controller.annotationManager != null) {
                    await controller.addMarkerAtPoint(result);
                    controller.mapboxMap?.setCamera(CameraOptions(center: result, zoom: 14.0));
                  }
                },
              ),
            ],
          ),
          drawer: SearchSuggestionDrawer(
            usePlaceName: controller.usePlaceName.value,
            searchSuggestions: controller.searchSuggestions,
            selectedSuggestion: controller.selectedSuggestion.value,
            onTogglePlaceName: (val) => controller.usePlaceName.value = val,
            onSuggestionSelected: (value) {
              controller.selectedSuggestion.value = value;
            },
            onCloseDrawer: () {
              Get.back();
            },
            onDeleteSuggestion: (suggestion, index) {
              if (suggestion == controller.selectedSuggestion.value && controller.searchSuggestions.length > 1) {
                controller.selectedSuggestion.value = controller.searchSuggestions.first;
              }
              controller.searchSuggestions.removeAt(index);
            },
            newSuggestionController: controller.newSuggestionController,
            onAddSuggestion: () {
              final newSuggestion = controller.newSuggestionController.text.trim();
              if (newSuggestion.isNotEmpty) {
                controller.searchSuggestions.add(newSuggestion);
                controller.newSuggestionController.clear();
              }
            },
          ),
          floatingActionButton:
              controller.showFetchButton.value
                  ? FloatingFetchButton(
                    onPressed: controller.isFetchingVideos.value ? null : () => controller.fetchAndShowVideos(context),
                    isLoading: controller.isFetchingVideos.value,
                  )
                  : null,
          body:
              controller.initialCamera.value == null
                  ? const Center(child: CupertinoActivityIndicator(radius: 30, color: Colors.black,))
                  : MapWidget(
                    key: const ValueKey("mapWidget"),
                    cameraOptions: controller.initialCamera.value!,
                    styleUri: MapboxStyles.MAPBOX_STREETS,
                    onMapCreated: (mapController) async {
                      controller.mapboxMap = mapController;
                      controller.annotationManager = await mapController.annotations.createPointAnnotationManager();

                      if (controller.markerLocation.value != null) {
                        controller.currentMarker = await controller.annotationManager!.create(
                          PointAnnotationOptions(isDraggable: true, geometry: controller.markerLocation.value!, image: await controller.loadDefaultMarkerImage(), iconSize: 0.5),
                        );
                      }
                    },
                    onTapListener: (gestureContext) async {
                      final position = gestureContext.point.coordinates;
                      final tappedPoint = Point(coordinates: position);

                      if (controller.currentMarker != null) {
                        await controller.annotationManager?.delete(controller.currentMarker!);
                      }

                      controller.currentMarker = await controller.annotationManager?.create(
                        PointAnnotationOptions(geometry: tappedPoint, isDraggable: true, image: await controller.loadDefaultMarkerImage(), iconSize: 0.5),
                      );

                      controller.selectedPlaceName.value = await ApiService.getPlaceNameFromCoordinates(
                        tappedPoint.coordinates.lat.toDouble(),
                        tappedPoint.coordinates.lng.toDouble(),
                      );

                      controller.markerLocation.value = tappedPoint;
                      controller.showFetchButton.value = true;
                    },
                  ),
        );
      }),
    );
  }
}
