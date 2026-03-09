import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/order_detailed.dart';
import 'package:projectqdel/view/Client/edit_order.dart';
import 'package:projectqdel/view/Client/order_tracking.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int _selectedTab = 0;
  Future<List<dynamic>?>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    print("🟢 MyOrdersScreen - initState called");
    _ordersFuture = ApiService().getAcceptedOrders();
  }

  String resolveOrderState(Map<String, dynamic> order) {
    final shipment = order["shipment_status"];
    if (shipment == null) {
      return "searching";
    }

    final status = shipment["status"]?.toString().toLowerCase();
    final trackingNo = shipment["carrier_tracking_no"];

    if (status == "pending" &&
        (trackingNo == null || trackingNo.toString().isEmpty)) {
      return "searching";
    }
    return status ?? "unknown";
  }

  Future<void> _loadOrders() async {
    setState(() {
      _ordersFuture = ApiService().getAcceptedOrders();
    });
  }

  Future<void> _onRefresh() async {
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: Column(
          children: [
            // _header(context),
            SizedBox(height: 50),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tabs(),
                    Expanded(child: _ordersFromApi()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorConstants.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [_tabItem("On-going", 0), _tabItem("Completed", 1)]),
    );
  }

  Widget _tabItem(String title, int index) {
    final bool isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          print("🟡 Tab changed to: $title (index: $index)");
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ordersFromApi() {
    return FutureBuilder<List<dynamic>?>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        print("🔵 FutureBuilder state: ${snapshot.connectionState}");

        if (snapshot.connectionState == ConnectionState.waiting) {
          print("⏳ Loading orders...");
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("🔴 FutureBuilder error: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print("🔴 No data received from API");
          return const Center(child: Text("Failed to load orders"));
        }

        final orders = snapshot.data!;
        print("📊 Total orders received: ${orders.length}");

        for (var i = 0; i < orders.length; i++) {
          print(
            "📦 Order ${i + 1}: ID=${orders[i]["id"]}, Status=${orders[i]["shipment_status"]?["status"]}",
          );
        }

        final filteredOrders = orders.where((order) {
          return _selectedTab == 0 ? isOngoing(order) : isCompleted(order);
        }).toList();

        print(
          "🎯 Filtered orders for tab ${_selectedTab}: ${filteredOrders.length}",
        );

        if (filteredOrders.isEmpty) {
          return Center(
            child: Text(
              _selectedTab == 0 ? "No ongoing orders" : "No completed orders",
            ),
          );
        }

        return ListView.separated(
          itemCount: filteredOrders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _orderCardFromApi(filteredOrders[index]);
          },
        );
      },
    );
  }

  bool canEditOrder(Map<String, dynamic> order) {
    return resolveOrderState(order) == "searching";
  }

  Widget _orderCardFromApi(Map<String, dynamic> order) {
    print("\n🟣 Rendering order card for order: ${order["id"]}");
    print("   Full order data: $order");

    final pickupNo = order["pickup_no"]?.toString() ?? "N/A";
    final productName = order["product_details"]?["name"] ?? "Product";
    final status = order["shipment_status"]?["status"];

    print("📦 Order ${order["id"]} - Status from API: '$status'");

    final int? pickupId = order["id"];
    final int? productId = order["product_details"]?["id"];
    final int? senderAddressId = order["sender_address"]?["id"];
    final int? senderId = order["sender_details"]?["id"];

    print("📊 Order ${order["id"]} - Extracted values:");
    print("   pickupId: $pickupId");
    print("   productId: $productId");
    print("   senderAddressId: $senderAddressId");
    print("   senderId: $senderId");
    print("   product_details: ${order["product_details"]}");
    print("   sender_address: ${order["sender_address"]}");
    print(
      "   sender_address_id from sender_address object: ${order["sender_address"]?["id"]}",
    );

    final bool canEdit = canEditOrder(order);

    print("✏️ Order ${order["id"]} - Can Edit: $canEdit");

    String statusText;
    Color statusColor;

    final resolvedState = resolveOrderState(order);
    switch (resolvedState) {
      case "searching":
        statusText = "SEARCHING";
        statusColor = Colors.orange;
        break;

      case "pending":
        statusText = "GOING TO PICKUP";
        statusColor = Colors.teal;
        break;

      case "arrived":
        statusText = "ARRIVED AT PICKUP";
        statusColor = Colors.blue;
        break;

      case "picked_up":
        statusText = "PICKED UP";
        statusColor = Colors.indigo;
        break;

      case "in_transit":
        statusText = "IN TRANSIT";
        statusColor = Colors.blueAccent;
        break;

      case "arrived_at_drop":
        statusText = "ARRIVED AT DROP";
        statusColor = Colors.green;
        break;

      case "delivered":
        statusText = "DELIVERED";
        statusColor = Colors.green;
        break;

      case "cancelled":
        statusText = "CANCELLED";
        statusColor = Colors.red;
        break;

      default:
        statusText = "UNKNOWN";
        statusColor = Colors.grey;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orderHeader(
            icon: Icons.inventory_2,
            title: productName,
            orderId: pickupNo,
            status: statusText,
            statusColor: statusColor,
          ),
          const SizedBox(height: 12),
          if (resolvedState == "searching")
            _infoTile(
              Icons.search,
              "Status",
              "Searching for delivery partners",
            ),

          if (resolvedState == "pending")
            _infoTile(
              Icons.assignment_turned_in,
              "Status",
              "Carrier accepted the order and going to pickup",
            ),

          if (resolvedState == "arrived")
            _infoTile(
              Icons.location_on,
              "Status",
              "Carrier arrived at pickup location",
            ),

          if (resolvedState == "picked_up")
            _infoTile(
              Icons.local_shipping,
              "Tracking No",
              order["shipment_status"]?["carrier_tracking_no"]?.toString() ??
                  "-",
            ),

          if (resolvedState == "in_transit")
            _infoTile(
              Icons.route,
              "Status",
              "Order is in transit to delivery location",
            ),

          if (resolvedState == "arrived_at_drop")
            _infoTile(
              Icons.location_pin,
              "Status",
              "Carrier arrived at drop location",
            ),

          if (resolvedState == "delivered")
            _infoTile(
              Icons.check_circle,
              "Delivered At",
              order["shipment_status"]?["delivered_at"]?.toString() ?? "-",
            ),

          if (resolvedState == "cancelled")
            _infoTile(Icons.cancel, "Status", "Order has been cancelled"),
          const SizedBox(height: 16),

          if (resolvedState == "searching") ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditOrder(
                            productId: productId!,
                            senderAddressId: senderAddressId!,
                            pickupId: pickupId!,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _ordersFuture = ApiService().getAcceptedOrders();
                        });
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: const Text(
                      "Edit",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(pickupId: pickupId!),
                        ),
                      );
                    },
                    child: const Text("Details"),
                  ),
                ),
              ],
            ),
          ] else if (isOngoing(order)) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(pickupId: pickupId!),
                        ),
                      );
                    },
                    child: const Text("Details"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            pickupId: pickupId!,
                            orderData: order,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.red,
                    ),
                    child: const Text(
                      "Track",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(pickupId: pickupId!),
                        ),
                      );
                    },
                    child: const Text("Details"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool isOngoing(Map<String, dynamic> order) {
    final state = resolveOrderState(order);

    return state == "searching" ||
        state == "pending" ||
        state == "arrived" ||
        state == "picked_up" ||
        state == "in_transit" ||
        state == "arrived_at_drop";
  }

  bool isCompleted(Map<String, dynamic> order) {
    final state = resolveOrderState(order);
    return state == "delivered" || state == "cancelled";
  }

  Widget _orderHeader({
    required IconData icon,
    required String title,
    required String orderId,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xffFFF3E0),
          child: Icon(icon, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.red, width: 2),
      ),
      child: child,
    );
  }
}
