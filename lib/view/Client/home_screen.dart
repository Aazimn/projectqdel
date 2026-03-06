import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:projectqdel/view/Client/order_detailed.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    loadProfile();
    loadOrders();
  }

  UserModel? user;
  List<dynamic>? allOrders;
  bool loading = true;
  bool ordersLoading = true;

  int pendingCount = 0;
  int activeCount = 0;
  int completedCount = 0;

  Future<void> loadProfile() async {
    final api = ApiService();
    user = await api.getMyProfile();
    setState(() => loading = false);
  }

  Future<void> loadOrders() async {
    setState(() => ordersLoading = true);
    try {
      final api = ApiService();
      final orders = await api.getAcceptedOrders();

      setState(() {
        allOrders = orders ?? [];
        _calculateStatusCounts();
        ordersLoading = false;
      });
    } catch (e) {
      print("Error loading orders: $e");
      setState(() {
        allOrders = [];
        ordersLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await loadOrders();
    await loadProfile();
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

  void _calculateStatusCounts() {
    if (allOrders == null || allOrders!.isEmpty) {
      pendingCount = 0;
      activeCount = 0;
      completedCount = 0;
      return;
    }

    pendingCount = 0;
    activeCount = 0;
    completedCount = 0;

    for (var order in allOrders!) {
      final state = resolveOrderState(order);

      if (state == "searching") {
        pendingCount++;
      } else if (state == "pending" ||
          state == "arrived" ||
          state == "picked_up" ||
          state == "in_transit" ||
          state == "arrived_at_drop") {
        activeCount++;
      } else if (state == "delivered") {
        completedCount++;
      }
    }

    print(
      "📊 Status Counts - Pending: $pendingCount, Active: $activeCount, Completed: $completedCount",
    );
  }

  List<dynamic> getActiveOrders() {
    if (allOrders == null) return [];
    return allOrders!.where((order) {
      final state = resolveOrderState(order);
      return state == "pending" ||
          state == "arrived" ||
          state == "picked_up" ||
          state == "in_transit" ||
          state == "arrived_at_drop";
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusCard(
                        "Pending",
                        ordersLoading ? "..." : pendingCount.toString(),
                        Icons.pending_actions,
                        subtitle: "Searching for partners",
                      ),
                      _statusCard(
                        "Active",
                        ordersLoading ? "..." : activeCount.toString(),
                        Icons.local_shipping,
                        subtitle: "Orders in progress",
                      ),
                      _statusCard(
                        "Completed",
                        ordersLoading ? "..." : completedCount.toString(),
                        Icons.check_circle,
                        subtitle: "Orders Delivered",
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Active Orders",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!ordersLoading && getActiveOrders().isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ClientDashboard(initialIndex: 2),
                              ),
                            );
                          },
                          child: const Text(
                            "View All",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ordersLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (getActiveOrders().isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No active orders",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ...getActiveOrders()
                        .take(3)
                        .map((order) => _buildOrderCardFromOrder(order))
                        .toList(),

                  if (!ordersLoading && getActiveOrders().length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ClientDashboard(initialIndex: 2),
                              ),
                            );
                          },
                          child: Text(
                            "+ ${getActiveOrders().length - 3} more active orders",
                            style: const TextStyle(color: ColorConstants.red),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final name = user != null
        ? "${user!.firstName} ${user!.lastName}"
        : "GUEST USER";
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        color: ColorConstants.red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: ColorConstants.red, size: 32),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome 👋", style: TextStyle(color: Colors.white70)),
              Column(
                children: [
                  Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      color: ColorConstants.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // if (user == null)
                  //   const Padding(
                  //     padding: EdgeInsets.only(top: 6),
                  //     child: Text(
                  //       "Profile data not available",
                  //       style: TextStyle(color: Colors.grey, fontSize: 12),
                  //     ),
                  //   ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(
    String title,
    String count,
    IconData icon, {
    String? subtitle,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: ColorConstants.red, size: 28),
          const SizedBox(height: 5),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorConstants.red,
            ),
          ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCardFromOrder(Map<String, dynamic> order) {
    final orderId = order["pickup_no"]?.toString() ?? "N/A";
    final productName = order["product_details"]?["name"] ?? "Product";
    final state = resolveOrderState(order);
    final pickupId = order["id"];

    String statusText;
    Color statusColor;

    switch (state) {
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
      default:
        statusText = state.toUpperCase();
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (pickupId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(pickupId: pickupId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Unable to open order details"),
                backgroundColor: ColorConstants.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory, size: 28, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
