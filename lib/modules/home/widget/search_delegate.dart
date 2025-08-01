import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as map;

import '../../../core/api_service.dart';
import '../../../data/models/place_result.dart';

class PlaceSearchDelegate extends SearchDelegate<map.Point?> {
  final LatLng? currentLocation;

  PlaceSearchDelegate({this.currentLocation});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return const Center(child: Text('Type at least 3 characters'));
    }
    return FutureBuilder<List<PlaceResult>>(
      future: ApiService.searchPlaces(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        final suggestions = snapshot.data!;
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final place = suggestions[index];
            return ListTile(
              title: Text(place.displayName),
              onTap: () {
                final lat = place.lat;
                final lon = place.lon;
                final point = map.Point(coordinates: map.Position(lon, lat));
                close(context, point);
              },
            );
          },
        );
      },
    );
  }
}
