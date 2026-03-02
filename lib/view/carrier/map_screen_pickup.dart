import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/model/order_model.dart';

class CarrierMapScreen extends StatefulWidget {
  const CarrierMapScreen({super.key});

  @override
  State<CarrierMapScreen> createState() => _CarrierMapScreenState();
}

class _CarrierMapScreenState extends State<CarrierMapScreen> {
  bool isLocationEnabled = false;
  bool isCheckingLocation = true;
  LatLng? carrierLocation;
  Future<List<OrderModel>>? ordersFuture;
  static const double radiusKm = 5.0;
  static const double radiusMeters = 5000;
  StreamSubscription<Position>? _locationStream;

  Future<void> _startLiveLocation() async {
    _locationStream?.cancel();

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50, // meters
          ),
        ).listen((position) {
          setState(() {
            carrierLocation = LatLng(position.latitude, position.longitude);
          });
        });
  }

  bool _isWithinRadius(OrderModel order) {
    if (carrierLocation == null) return false;

    final lat = order.senderAddress?.latitude;
    final lng = order.senderAddress?.longitude;

    if (lat == null || lng == null) return false;

    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      lat,
      lng,
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
        ordersFuture = null;
        isCheckingLocation = false;
      });
    } else {
      setState(() {
        isLocationEnabled = true;
        carrierLocation = location;
        ordersFuture = ApiService().getAllOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: const Center(
          child: Text(
            "Pickup Orders",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),

      body: isCheckingLocation
          ? const Center(child: CircularProgressIndicator())
          : (!isLocationEnabled ? _locationOffUI() : _mapWithOrders()),
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
              "Location access is required to view pickup orders.\nPlease enable GPS.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                setState(() => isCheckingLocation = true);

                final enabled = await _enableLocation();

                if (enabled) {
                  await _checkLocationAndFetch(); // 🔥 reload map automatically
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

  Widget _mapWithOrders() {
    return FutureBuilder<List<OrderModel>>(
      future: ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error loading orders: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final orders = snapshot.data ?? [];
        print("Total orders received: ${orders.length}");

        final validOrders = orders
            .where(_hasValidLocation)
            .where(_isWithinRadius)
            .toList();

        print("📦 Orders inside 5 km radius: ${validOrders.length}");
        print("Orders with valid locations: ${validOrders.length}");
        print(
          "📍 Carrier location: ${carrierLocation?.latitude}, ${carrierLocation?.longitude}",
        );

        for (var i = 0; i < validOrders.length; i++) {
          final order = validOrders[i];
          print("🔍 Valid Order $i - ID: ${order.id}");
          print("   Lat: ${order.senderAddress!.latitude}");
          print("   Lng: ${order.senderAddress!.longitude}");
          print("   Address: ${order.senderAddress!.address}");
        }
        if (validOrders.length > 1) {
          for (var i = 0; i < validOrders.length; i++) {
            for (var j = i + 1; j < validOrders.length; j++) {
              final lat1 = validOrders[i].senderAddress!.latitude!;
              final lng1 = validOrders[i].senderAddress!.longitude!;
              final lat2 = validOrders[j].senderAddress!.latitude!;
              final lng2 = validOrders[j].senderAddress!.longitude!;

              final distance = (lat1 - lat2).abs() + (lng1 - lng2).abs();
              print(
                "📏 Distance between order ${validOrders[i].id} and ${validOrders[j].id}: $distance",
              );

              if (distance < 0.0001) {
                print(
                  "⚠️ Orders are VERY close together - markers might be overlapping!",
                );
              }
            }
          }
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
        for (var i = 0; i < validOrders.length; i++) {
          final order = validOrders[i];
          markers.add(
            Marker(
              key: Key('order_${order.id}'),
              point: LatLng(
                order.senderAddress!.latitude!,
                order.senderAddress!.longitude!,
              ),
              width: 80,
              height: 50,
              child: GestureDetector(
                onTap: () => _showOrderDetails(order),
                child: Container(
                  // decoration: BoxDecoration(
                  //   color: ColorConstants.red.withOpacity(0.3),
                  //   shape: BoxShape.circle,
                  //   border: Border.all(color: ColorConstants.red, width: 2),
                  // ),
                  child: Lottie.asset(
                    "assets/lottie_assets/location.json",
                    repeat: true,
                    animate: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        }

        print("🎯 Total markers to display: ${markers.length}");

        if (validOrders.isNotEmpty && carrierLocation != null) {
          final allPoints = [
            carrierLocation!,
            ...validOrders.map(
              (o) => LatLng(
                o.senderAddress!.latitude!,
                o.senderAddress!.longitude!,
              ),
            ),
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

  bool _hasValidLocation(OrderModel order) {
    if (order.senderAddress == null) {
      print("Order ${order.id}: No senderAddress");
      return false;
    }

    final lat = order.senderAddress?.latitude;
    final lng = order.senderAddress?.longitude;

    if (lat == null || lng == null) {
      print("Order ${order.id}: Missing lat or lng");
      return false;
    }

    print("✅ Order ${order.id}: Valid location - ($lat, $lng)");
    return true;
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 187, 185, 185),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order #${order.id}",
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.black,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.call_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.circle,

                            size: 10,
                            color: Colors.black,
                          ),
                          Container(
                            width: 2,
                            height: 100,
                            color: const Color.fromARGB(255, 96, 95, 95),
                          ),
                          const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pickup",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 95, 95, 95),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              order.senderDetails!.fullName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              order.senderAddress != null
                                  ? order.senderAddress!.address
                                  : "Pickup address not available",
                              style: const TextStyle(color: Colors.black54),
                            ),

                            const SizedBox(height: 50),
                            const Text(
                              "Deliver To",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color.fromARGB(255, 95, 95, 95),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              order.receiverAddress?.receiverName
                                      .toUpperCase() ??
                                  "Receiver",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              order.receiverAddress != null
                                  ? "${order.receiverAddress!.address}, "
                                        "${order.receiverAddress!.district}, "
                                        "${order.receiverAddress!.state}, "
                                        "${order.receiverAddress!.country}"
                                  : "Delivery address not available",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Accept order",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _enableLocation() async {
    // 1️⃣ Check if GPS is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }

    // 2️⃣ Check permission
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
