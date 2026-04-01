// lib/view/Carrier/drop_location_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/web.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/drop_location.dart';
import 'package:projectqdel/services/api_service.dart';

class DropLocationScreen extends StatefulWidget {
  const DropLocationScreen({super.key});

  @override
  State<DropLocationScreen> createState() => _DropLocationScreenState();
}

class _DropLocationScreenState extends State<DropLocationScreen> {
  bool isLocationEnabled = false;
  bool isCheckingLocation = true;
  Logger logger = Logger();
  LatLng? carrierLocation;
  Future<List<DropLocation>>? dropLocationsFuture;
  static const double radiusMeters = 5000;
  StreamSubscription<Position>? _locationStream;

  Future<void> _startLiveLocation() async {
    _locationStream?.cancel();

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((position) async {
          setState(() {
            carrierLocation = LatLng(position.latitude, position.longitude);
          });

          try {
            int? pickupCarrierId = await ApiService.getPickupCarrierId();

            if (pickupCarrierId == null) {
              logger.w("⚠️ pickupCarrierId not available yet");
              return;
            }

            await ApiService().updateCarrierLocation(
              pickupCarrierId: pickupCarrierId,
              latitude: position.latitude,
              longitude: position.longitude,
            );

            logger.i(
              "📍 Location Updated -> ${position.latitude}, ${position.longitude} | ID: $pickupCarrierId",
            );
          } catch (e) {
            logger.e("❌ Live location update error: $e");
          }
        });
  }

  bool _isWithinRadius(DropLocation location) {
    if (carrierLocation == null) return false;

    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      location.latitude,
      location.longitude,
    );

    return distance <= radiusMeters;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocationAndFetch();
  }

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetch();
  }

  Future<void> _checkLocationAndFetch() async {
    setState(() {
      isCheckingLocation = true;
    });

    final location = await ApiService().getCarrierCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      setState(() {
        isLocationEnabled = false;
        carrierLocation = null;
        dropLocationsFuture = null;
        isCheckingLocation = false;
      });
    } else {
      setState(() {
        isLocationEnabled = true;
        carrierLocation = location;
        dropLocationsFuture = ApiService().getDropLocations();
        isCheckingLocation = false;
      });
      _startLiveLocation();
    }
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Exit Confirmation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Exit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorConstants.red,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Drop Locations",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: isCheckingLocation
            ? const Center(child: CircularProgressIndicator())
            : (!isLocationEnabled ? _locationOffUI() : _mapWithDropLocations()),
      ),
    );
  }

  Widget _locationOffUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Location access is required to view drop locations.\nPlease enable GPS.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                setState(() => isCheckingLocation = true);

                final enabled = await _enableLocation();

                if (enabled) {
                  await _checkLocationAndFetch();
                } else {
                  setState(() => isCheckingLocation = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
              ),
              child: const Text(
                "Enable Location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapWithDropLocations() {
    return FutureBuilder<List<DropLocation>>(
      future: dropLocationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error loading drop locations: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final locations = snapshot.data ?? [];
        print("Total drop locations received: ${locations.length}");

        final validLocations = locations
            .where(
              (location) => location.latitude != 0 && location.longitude != 0,
            )
            .where(_isWithinRadius)
            .toList();

        print("📦 Drop locations inside 5 km radius: ${validLocations.length}");
        print(
          "📍 Carrier location: ${carrierLocation?.latitude}, ${carrierLocation?.longitude}",
        );

        for (var i = 0; i < validLocations.length; i++) {
          final location = validLocations[i];
          print("🔍 Valid Location $i - ID: ${location.id}");
          print("   Lat: ${location.latitude}");
          print("   Lng: ${location.longitude}");
          print("   Address: ${location.address}");
          print("   Shop: ${location.userDetails.shopName}");
        }

        final markers = <Marker>[
          Marker(
            point: carrierLocation!,
            width: 50,
            height: 50,
            child: Lottie.asset(
              "assets/lottie_assets/carrier_location.json",
              repeat: true,
              animate: true,
              fit: BoxFit.contain,
            ),
          ),
        ];

        for (var i = 0; i < validLocations.length; i++) {
          final location = validLocations[i];
          markers.add(
            Marker(
              key: Key('location_${location.id}'),
              point: LatLng(location.latitude, location.longitude),
              width: 80,
              height: 50,
              child: GestureDetector(
                onTap: () => _showLocationDetails(location),
                child: Lottie.asset(
                  "assets/lottie_assets/location.json",
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }

        print("🎯 Total markers to display: ${markers.length}");

        if (validLocations.isNotEmpty && carrierLocation != null) {
          final allPoints = [
            carrierLocation!,
            ...validLocations.map((l) => LatLng(l.latitude, l.longitude)),
          ];

          double minLat = allPoints
              .map((p) => p.latitude)
              .reduce((a, b) => a < b ? a : b);
          double maxLat = allPoints
              .map((p) => p.latitude)
              .reduce((a, b) => a > b ? a : b);
          double minLng = allPoints
              .map((p) => p.longitude)
              .reduce((a, b) => a < b ? a : b);
          double maxLng = allPoints
              .map((p) => p.longitude)
              .reduce((a, b) => a > b ? a : b);

          print(
            "📍 Map bounds - Lat: $minLat to $maxLat, Lng: $minLng to $maxLng",
          );
          final centerLat = (minLat + maxLat) / 2;
          final centerLng = (minLng + maxLng) / 2;
          final latSpread = (maxLat - minLat).abs();
          final lngSpread = (maxLng - minLng).abs();
          final maxSpread = latSpread > lngSpread ? latSpread : lngSpread;

          double zoomLevel;
          if (maxSpread > 0.1)
            zoomLevel = 11;
          else if (maxSpread > 0.05)
            zoomLevel = 12;
          else if (maxSpread > 0.01)
            zoomLevel = 13;
          else if (maxSpread > 0.005)
            zoomLevel = 14;
          else
            zoomLevel = 15;

          print(
            "📍 Map center: ($centerLat, $centerLng), Zoom: $zoomLevel, Spread: $maxSpread",
          );

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: zoomLevel,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.projectqdel',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: carrierLocation!,
                    radius: radiusMeters,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(markers: markers),
            ],
          );
        }
        return FlutterMap(
          options: MapOptions(initialCenter: carrierLocation!, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.projectqdel',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  void _showLocationDetails(DropLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shop Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store,
                      size: 40,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shop Name
                  Text(
                    location.userDetails.shopName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Shop Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      location.userDetails.shopCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Owner Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.person,
                          "Name",
                          "${location.userDetails.firstName} ${location.userDetails.lastName}",
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.phone,
                          "Phone",
                          location.userDetails.phone,
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          "Address Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.location_on,
                          "Address",
                          location.address,
                        ),
                        if (location.landmark != null &&
                            location.landmark!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoRow(
                              Icons.flag,
                              "Landmark",
                              location.landmark!,
                            ),
                          ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.pin_drop,
                          "Zip Code",
                          location.zipCode,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.location_city,
                          "District",
                          location.locationDetails.district,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.map,
                          "State",
                          location.locationDetails.state,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.public,
                          "Country",
                          location.locationDetails.country,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Selected drop location: ${location.userDetails.shopName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Select This Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.red.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _enableLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }
}
