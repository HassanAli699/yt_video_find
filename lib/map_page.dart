import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geoLocation;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_videos_fetch/search_delegate.dart';
import 'package:latlong2/latlong.dart' as LatLng2;

import 'api_key.dart';

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldMessengerState> _bottomSheetKey = GlobalKey<ScaffoldMessengerState>();

  MapboxMap? _mapboxMap;
  CameraOptions? _initialCamera;
  Point? _markerLocation;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _currentMarker;
  bool _showFetchButton = false;
  List<Map<String, dynamic>> _videos = [];
  bool _isFetchingVideos = false;
  String _selectedPlaceName = "";
  String? _nextPageToken;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool _usePlaceName = true;
  final List<String> _searchSuggestions = ['Things to do in', 'Events in', 'Exploring', "Travel vlog in"];
  String _selectedSuggestion = 'Things to do in';
  final TextEditingController _newSuggestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    geoLocation.LocationPermission permission;

    permission = await geoLocation.Geolocator.checkPermission();
    if (permission == geoLocation.LocationPermission.denied) {
      permission = await geoLocation.Geolocator.requestPermission();
    }

    final position = await geoLocation.Geolocator.getCurrentPosition();

    setState(() {
      _markerLocation = Point(coordinates: Position(position.longitude, position.latitude));

      _initialCamera = CameraOptions(center: Point(coordinates: Position(position.longitude, position.latitude)), zoom: 14.0);
    });
  }

  Future<Uint8List> _loadDefaultMarkerImage() async {
    final ByteData byteData = await rootBundle.load('assets/images/marker.png');
    return byteData.buffer.asUint8List();
  }

  void _addMarkerAtPoint(Point point) async {
    if (_currentMarker != null) {
      await _annotationManager?.delete(_currentMarker!);
    }
    _currentMarker = await _annotationManager?.create(PointAnnotationOptions(geometry: point, image: await _loadDefaultMarkerImage(), iconSize: 0.5));

    _selectedPlaceName = await getPlaceNameFromCoordinates(point.coordinates.lat.toDouble(), point.coordinates.lng.toDouble());

    _markerLocation = point;
  }

  void _launchYoutubeApp(String videoId) {
    final intent = AndroidIntent(
      action: 'action_view',
      data: 'vnd.youtube:$videoId',
      package: 'com.google.android.youtube',
    );
    intent.launch();
  }


  void _fetchAndShowVideos() async {
    setState(() => _isFetchingVideos = true);

    final lat = _markerLocation!.coordinates.lat.toDouble();
    final lon = _markerLocation!.coordinates.lng.toDouble();


    final query = _usePlaceName
        ? '$_selectedSuggestion $_selectedPlaceName'
        : ''; // Only location

    final result = await fetchYouTubeVideos(lat: lat, lon: lon, placeName:  query);

    setState(() {
      _videos = result['videos'];
      _nextPageToken = result['nextPageToken'];
      _hasMore = _nextPageToken != null;
      _isFetchingVideos = false;
    });


    if (_videos.isNotEmpty) {
      _showVideoBottomSheet();
    } else {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('No videos found.')));
    }
  }


  void _showVideoBottomSheet() {
    showModalBottomSheet(
      context: _scaffoldMessengerKey.currentContext!,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                // Store for later when loading more

                void loadMoreVideosInSheet() async {
                  if (_nextPageToken == null || _isLoadingMore) return;
                  setSheetState(() => _isLoadingMore = true);

                  final lat = _markerLocation!.coordinates.lat.toDouble();
                  final lon = _markerLocation!.coordinates.lng.toDouble();

                  final query = _usePlaceName
                      ? '$_selectedSuggestion $_selectedPlaceName'
                      : ''; // Only location


                  final result = await fetchYouTubeVideos(
                      lat: lat,
                      lon: lon,
                      pageToken: _nextPageToken,
                    placeName: query,
                  );

                  setState(() {
                    _videos.addAll(result['videos']);
                    _nextPageToken = result['nextPageToken'];
                    _hasMore = _nextPageToken != null;
                    _isLoadingMore = false;
                  });

                  setSheetState(() {}); // Rebuild the bottom sheet
                }


                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                        child: Text(
                          _usePlaceName
                              ? 'Showing videos for "${'$_selectedSuggestion $_selectedPlaceName'}"'
                              : 'Showing videos near selected location',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: _videos.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _videos.length && _hasMore) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: ElevatedButton.icon(
                                    icon: _isLoadingMore
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : const Icon(Icons.expand_more),
                                    label: const Text('Load more'),
                                    onPressed: _isLoadingMore ? null : loadMoreVideosInSheet,
                                  ),
                                ),
                              );
                            }

                            final video = _videos[index];
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
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        floatingActionButton:
            _showFetchButton
                ? FloatingActionButton.extended(
                  onPressed: () => _isFetchingVideos ? null : _fetchAndShowVideos(),
                  label: _isFetchingVideos ? CircularProgressIndicator(color: Colors.black) : Text("Fetch Videos"),
                  icon: _isFetchingVideos ? null : Icon(Icons.video_collection) ,
                )
                : null,

        drawer: Drawer(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("Search Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  SwitchListTile(
                    title: const Text("Use Place name in search"),

                    value: _usePlaceName,
                    onChanged: (val) {
                      setState(() => _usePlaceName = val);
                    },
                  ),


                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("Search Suggestions", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _searchSuggestions[index];
                      return ListTile(
                        title: Text(suggestion),
                        leading: Radio<String>(
                          value: suggestion,
                          groupValue: _selectedSuggestion,
                          onChanged: (value) {
                            setState(() => _selectedSuggestion = value!);
                            Navigator.pop(context); // Close drawer
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              if (_searchSuggestions[index] == _selectedSuggestion) {
                                _selectedSuggestion = _searchSuggestions.first;
                              }
                              _searchSuggestions.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.black45)),
                        SizedBox(width: 10,),
                        Text("OR",),
                        SizedBox(width: 10,),
                        const Expanded(child: Divider(color: Colors.black45)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newSuggestionController,
                            decoration: InputDecoration(
                              suffixIcon: TextButton(
                                child:  Icon(CupertinoIcons.add, color: Colors.black,size: 24,),
                                onPressed: () {
                                  final newSuggestion = _newSuggestionController.text.trim();
                                  if (newSuggestion.isNotEmpty) {
                                    setState(() {
                                      _searchSuggestions.add(newSuggestion);
                                      _newSuggestionController.clear();
                                    });
                                  }
                                },
                              ),
                              hintText: 'Add Suggestions...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        appBar: AppBar(
          title: const Text('YT Video Find', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final result = await showSearch<Point?>(
                  context: context,
                  delegate: PlaceSearchDelegate(
                    currentLocation:
                        _markerLocation?.coordinates != null ? LatLng2.LatLng(_markerLocation!.coordinates.lat.toDouble(), _markerLocation!.coordinates.lng.toDouble()) : null,
                  ),
                );
                if (result != null && _mapboxMap != null && _annotationManager != null) {
                  _addMarkerAtPoint(result);
                  _mapboxMap?.setCamera(CameraOptions(center: result, zoom: 14.0));
                }
              },
            ),
          ],
        ),
        body: MapWidget(
          key: const ValueKey("mapWidget"),
          cameraOptions: _initialCamera,
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapCreated: (controller) async {
            _mapboxMap = controller;

            _annotationManager = await controller.annotations.createPointAnnotationManager();

            if (_markerLocation != null) {
              _currentMarker = await _annotationManager!.create(
                PointAnnotationOptions(isDraggable: true, geometry: _markerLocation!, image: await _loadDefaultMarkerImage(), iconSize: 0.5),
              );
            }
          },
          onTapListener: (MapContentGestureContext context) async {
            final position = context.point.coordinates;

            final tappedPoint = Point(coordinates: position);

            // Remove previous marker if any
            if (_currentMarker != null) {
              await _annotationManager?.delete(_currentMarker!);
            }

            // Add new marker
            _currentMarker = await _annotationManager?.create(
              PointAnnotationOptions(geometry: tappedPoint, isDraggable: true, image: await _loadDefaultMarkerImage(), iconSize: 0.5),
            );

            _selectedPlaceName = await getPlaceNameFromCoordinates(tappedPoint.coordinates.lat.toDouble(), tappedPoint.coordinates.lng.toDouble());

            setState(() {
              _markerLocation = tappedPoint;
              _showFetchButton = true;
            });
          },
        ),
      ),
    );
  }
}
