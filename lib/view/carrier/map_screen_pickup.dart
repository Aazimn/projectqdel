import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  late Future<List<OrderModel>> ordersFuture;

  @override
  void initState() {
    super.initState();
    ordersFuture = ApiService().getAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: Center(
          child: Text(
            "Pickup Orders",
            style: TextStyle(
              color: ColorConstants.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load orders"));
          }

          final orders = snapshot.data ?? [];
          final markers = orders
              .where((o) => _hasValidLocation(o))
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
              )
              .toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(9.931233, 76.267303),
              initialZoom: 13,
            ),
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
      ),
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
}
