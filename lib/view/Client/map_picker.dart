import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng selectedLocation = LatLng(9.931233, 76.267303); 
  bool isSearching = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => isSearching = true);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);

        setState(() {
          selectedLocation = LatLng(lat, lon);
        });

        _mapController.move(selectedLocation, 15);
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }

    setState(() => isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 14,
              onTap: (_, latLng) {
                setState(() {
                  selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/topo-v4/{z}/{x}/{y}.png?key=smYymRDsqSZrgB4sO5oG",
                userAgentPackageName: 'com.example.projectqdel',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchLocation,
                decoration: InputDecoration(
                  hintText: "Search location",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (_searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                              },
                            )
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}