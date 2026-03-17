import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialLocationName;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialLocationName,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController();

  late LatLng selectedLocation;
  bool isSearching = false;
  bool isGettingLocationName = false;
  String? selectedLocationName;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      selectedLocationName = widget.initialLocationName;
    } else {
      selectedLocation = const LatLng(9.931233, 76.267303); 
    }

    if (widget.initialLatitude != null && 
        widget.initialLongitude != null && 
        widget.initialLocationName == null) {
      _getLocationNameFromCoordinates(selectedLocation);
    }
  }

  @override
  void didUpdateWidget(MapPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  
    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
          selectedLocationName = widget.initialLocationName;
        });
        _mapController.move(selectedLocation, 15);
      }
    }
  }

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
        final displayName = data[0]['display_name'];

        setState(() {
          selectedLocation = LatLng(lat, lon);
          selectedLocationName = displayName;
        });

        _mapController.move(selectedLocation, 15);
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }

    setState(() => isSearching = false);
  }

  Future<void> _getLocationNameFromCoordinates(LatLng position) async {
    setState(() => isGettingLocationName = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          selectedLocationName =
              data['display_name'] ??
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      } else {
        setState(() {
          selectedLocationName =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      setState(() {
        selectedLocationName =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    }

    setState(() => isGettingLocationName = false);
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      selectedLocation = latLng;
      selectedLocationName = null; 
    });
    _getLocationNameFromCoordinates(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15,
              onTap: (_, latLng) => _onMapTapped(latLng),
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
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : (_searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.red,
                              ),
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

          if (selectedLocationName != null || isGettingLocationName)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selected Location",
                            style: TextStyle(
                              fontSize: 12,
                              color: AddressColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isGettingLocationName)
                            const Row(
                              children: [
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Getting location name...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AddressColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              selectedLocationName ??
                                  '${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AddressColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: isGettingLocationName
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'latitude': selectedLocation.latitude,
                        'longitude': selectedLocation.longitude,
                        'locationName':
                            selectedLocationName ??
                            '${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}',
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: isGettingLocationName
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Confirm Location",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddressColors {
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textPrimary = Color(0xFF1E293B);
}