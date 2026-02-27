import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
    }
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
        final orders = snapshot.data ?? []; // 👈 empty if error / loading

        final markers = <Marker>[
          // 🧍 Carrier marker (ALWAYS)
          Marker(
            point: carrierLocation!,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.blue,
              size: 40,
            ),
          ),

          // 📦 Order markers (ONLY if valid)
          ...orders
              .where(_hasValidLocation)
              .map(
                (order) => Marker(
                  point: LatLng(
                    double.parse(order.latitude!),
                    double.parse(order.longitude!),
                  ),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showOrderDetails(order),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
              ),
        ];

        return FlutterMap(
          options: MapOptions(initialCenter: carrierLocation!, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate:
                  "https://api.maptiler.com/maps/topo-v4/{z}/{x}/{y}.png?key=smYymRDsqSZrgB4sO5oG",
              userAgentPackageName: 'com.example.projectqdel',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  bool _hasValidLocation(OrderModel order) {
    if (order.latitude == null || order.longitude == null) return false;

    final lat = double.tryParse(order.latitude!);
    final lng = double.tryParse(order.longitude!);

    return lat != null && lng != null;
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
                              order.receiverName!.toUpperCase() ?? "Receiver",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              order.addressText!,
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
