import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/order_detailed.dart';
import 'package:projectqdel/view/Client/order_placing.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: Column(
        children: [
          _header(context),
          // SizedBox(height: 50),
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
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2F7),
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
                color: isSelected ? Colors.black : Colors.grey,
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

        // Print all orders for debugging
        for (var i = 0; i < orders.length; i++) {
          print(
            "📦 Order ${i + 1}: ID=${orders[i]["id"]}, Status=${orders[i]["shipment_status"]?["status"]}",
          );
        }

        final filteredOrders = orders.where((order) {
          final status = order["shipment_status"]?["status"];
          final isOngoingStatus = isOngoing(status);
          final isCompletedStatus = isCompleted(status);

          print(
            "🔍 Filter check - Order ${order["id"]}: status='$status', isOngoing=$isOngoingStatus, isCompleted=$isCompletedStatus",
          );

          return _selectedTab == 0 ? isOngoingStatus : isCompletedStatus;
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

  // Helper method to check if order is in searching state (can be edited)
  bool _canEditOrder(String? status) {
    // Debug print to see actual status value
    print("🔍 Checking edit permission for status: '$status'");

    // Check for searching status (case insensitive)
    if (status == null) {
      print("⚠️ Status is null - allowing edit");
      return true;
    }

    final statusLower = status.toLowerCase();
    final canEdit =
        statusLower == "not assigned" ||
        statusLower == "searching" ||
        statusLower == "not_assigned" ||
        statusLower.contains("search");

    print("   Edit permission result: $canEdit");
    return canEdit;
  }

  Widget _orderCardFromApi(Map<String, dynamic> order) {
    print("\n🟣 Rendering order card for order: ${order["id"]}");
    print("   Full order data: $order");

    final pickupNo = order["pickup_no"]?.toString() ?? "N/A";
    final productName = order["product_details"]?["name"] ?? "Product";
    final status = order["shipment_status"]?["status"];

    // Debug print to see the actual status from API
    print("📦 Order ${order["id"]} - Status from API: '$status'");

    // Get IDs for navigation - FIXED: Get senderAddressId from sender_address object
    final int? pickupId = order["id"];
    final int? productId = order["product_details"]?["id"];

    // Fix: Get sender address ID from the nested sender_address object
    final int? senderAddressId = order["sender_address"]?["id"];

    // Also try to get from sender_details if needed for other purposes
    final int? senderId = order["sender_details"]?["id"];

    // Debug print the extracted values
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

    // Check if order can be edited
    final bool canEdit = _canEditOrder(status);

    // Debug print to confirm edit permission
    print("✏️ Order ${order["id"]} - Can Edit: $canEdit");

    String statusText;
    Color statusColor;

    // Normalize status for display
    final displayStatus = status?.toLowerCase() ?? "";

    switch (displayStatus) {
      case "not assigned":
      case "searching":
      case "not_assigned":
        statusText = "SEARCHING";
        statusColor = Colors.orange;
        break;

      case "pending":
        statusText = "GOING TO PICKUP";
        statusColor = const Color.fromARGB(255, 6, 196, 158);
        break;

      case "arrived":
        statusText = "ARRIVED AT PICKUP";
        statusColor = const Color.fromARGB(255, 10, 10, 234);
        break;

      case "picked_up":
        statusText = "PICKED UP";
        statusColor = const Color.fromARGB(255, 0, 123, 255);
        break;

      case "in_transit":
        statusText = "IN TRANSIT";
        statusColor = Colors.blue;
        break;

      case "arrived_at_drop":
        statusText = "ARRIVED AT DROP";
        statusColor = const Color.fromARGB(255, 58, 160, 68);
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
        print("⚠️ Unknown status: '$status'");
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
          if (displayStatus.contains("search") ||
              displayStatus == "not assigned")
            _infoTile(
              Icons.search,
              "Status",
              "Searching for delivery partners",
            ),

          if (displayStatus == "pending")
            _infoTile(
              Icons.assignment_turned_in,
              "Status",
              "Carrier accepted the order and going to pickup",
            ),

          if (displayStatus == "arrived")
            _infoTile(
              Icons.location_on,
              "Status",
              "Carrier arrived at pickup location",
            ),

          if (displayStatus == "picked_up")
            _infoTile(
              Icons.local_shipping,
              "Tracking No",
              order["shipment_status"]?["carrier_tracking_no"]?.toString() ??
                  "-",
            ),

          if (displayStatus == "in_transit")
            _infoTile(
              Icons.route,
              "Status",
              "Order is in transit to delivery location",
            ),

          if (displayStatus == "arrived_at_drop")
            _infoTile(
              Icons.location_pin,
              "Status",
              "Carrier arrived at drop location",
            ),

          if (displayStatus == "delivered")
            _infoTile(
              Icons.check_circle,
              "Delivered At",
              order["shipment_status"]?["delivered_at"]?.toString() ?? "-",
            ),

          if (displayStatus == "cancelled")
            _infoTile(Icons.cancel, "Status", "Order has been cancelled"),
          const SizedBox(height: 16),

          // Button Row with conditional Edit button
          if (displayStatus != "delivered" && displayStatus != "cancelled")
            Row(
              children: [
                // Edit Button - only enabled for searching orders
                Expanded(
                  child: OutlinedButton(
                    onPressed: canEdit
                        ? () {
                            print(
                              "\n🟡 EDIT BUTTON CLICKED FOR ORDER ${order["id"]}",
                            );

                            // Debug prints to check values
                            print("🔍 EDIT BUTTON CLICKED - Checking values:");
                            print("   pickupId: $pickupId");
                            print("   productId: $productId");
                            print("   senderAddressId: $senderAddressId");
                            print("   senderId: $senderId");

                            if (pickupId == null) {
                              print("❌ pickupId is null");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Cannot edit this order - missing pickup ID",
                                  ),
                                ),
                              );
                              return;
                            }

                            if (productId == null) {
                              print("❌ productId is null");
                              print(
                                "   product_details: ${order["product_details"]}",
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Cannot edit this order - missing product ID",
                                  ),
                                ),
                              );
                              return;
                            }

                            if (senderAddressId == null) {
                              print("❌ senderAddressId is null");
                              print(
                                "   sender_address: ${order["sender_address"]}",
                              );

                              // Try to get from alternative location if needed
                              if (order["sender_address"] != null) {
                                print(
                                  "   sender_address exists but ID is missing",
                                );
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Cannot edit this order - missing sender address ID",
                                  ),
                                ),
                              );
                              return;
                            }

                            print(
                              "✅ All values present! Navigating to edit screen with:",
                            );
                            print("   pickupId: $pickupId");
                            print("   productId: $productId");
                            print("   senderAddressId: $senderAddressId");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderPlacedScreen(
                                  productId: productId,
                                  senderAddressId: senderAddressId,
                                  pickupId: pickupId,
                                ),
                              ),
                            ).then((_) {
                              print(
                                "🔄 Returned from OrderPlacedScreen, refreshing orders...",
                              );
                              setState(() {
                                _ordersFuture = ApiService()
                                    .getAcceptedOrders();
                              });
                            });
                          }
                        : null, // Disable if canEdit is false
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canEdit ? Colors.blue : Colors.grey,
                      ),
                    ),
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        color: canEdit ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Details Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      print(
                        "\n🟡 DETAILS BUTTON CLICKED FOR ORDER ${order["id"]}",
                      );

                      if (pickupId == null) {
                        print("❌ pickupId is null");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid pickup ID")),
                        );
                        return;
                      }

                      print(
                        "✅ Navigating to OrderDetailsScreen with pickupId: $pickupId",
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(pickupId: pickupId),
                        ),
                      );
                    },
                    child: const Text(
                      "Details",
                      style: TextStyle(color: ColorConstants.black),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Track Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print(
                        "\n🟡 TRACK BUTTON CLICKED FOR ORDER ${order["id"]}",
                      );
                      // Implement track functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Track feature coming soon"),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "Track",
                      style: TextStyle(color: ColorConstants.white),
                    ),
                  ),
                ),
              ],
            )
          else
            // For delivered/cancelled orders, show only Details button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      print(
                        "\n🟡 DETAILS BUTTON CLICKED FOR COMPLETED ORDER ${order["id"]}",
                      );

                      if (pickupId == null) {
                        print("❌ pickupId is null");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid pickup ID")),
                        );
                        return;
                      }

                      print(
                        "✅ Navigating to OrderDetailsScreen with pickupId: $pickupId",
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(pickupId: pickupId),
                        ),
                      );
                    },
                    child: const Text(
                      "Details",
                      style: TextStyle(color: ColorConstants.black),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool isOngoing(String? status) {
    final statusLower = status?.toLowerCase() ?? "";
    final result =
        statusLower.contains("search") ||
        statusLower == "not assigned" ||
        statusLower == "pending" ||
        statusLower == "arrived" ||
        statusLower == "picked_up" ||
        statusLower == "in_transit" ||
        statusLower == "arrived_at_drop";

    print("🔍 isOngoing check for status '$status': $result");
    return result;
  }

  bool isCompleted(String? status) {
    final statusLower = status?.toLowerCase() ?? "";
    final result = statusLower == "delivered" || statusLower == "cancelled";

    print("🔍 isCompleted check for status '$status': $result");
    return result;
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              border: Border.all(color: Colors.red, width: 3),
            ),
            height: 110,
            width: double.infinity,
            // child: Lottie.asset(
            //   "assets/lottie_assets/food.json",
            //   fit: BoxFit.fitWidth,
            // ),
            child: Image.asset(
              "assets/image_assets/qdel_bike_2.jpeg",
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Positioned(
        //   bottom: -60,
        //   left: 0,
        //   right: 0,
        //   child: Center(
        //     child: Stack(
        //       children: [
        //         Container(
        //           height: 100,
        //           width: 100,
        //           decoration: BoxDecoration(
        //             shape: BoxShape.circle,
        //             border: Border.all(color: Colors.red, width: 4),

        //             color: Colors.white,
        //           ),
        //           child: Image.asset(
        //             "assets/image_assets/logo_qdel.png",
        //             fit: BoxFit.contain,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
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
        border: Border.all(color: ColorConstants.black),
      ),
      child: child,
    );
  }
}
