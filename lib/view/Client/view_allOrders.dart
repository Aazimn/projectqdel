// import 'package:flutter/material.dart';
// import 'package:projectqdel/services/api_service.dart';

// class OrderListScreen extends StatefulWidget {
//   const OrderListScreen({super.key});

//   @override
//   State<OrderListScreen> createState() => _OrderListScreenState();
// }

// class _OrderListScreenState extends State<OrderListScreen> {
//   int selectedTab = 0;
//   Future<List<dynamic>?>? ordersFuture;
//   @override
//   void initState() {
//     super.initState();
//     ordersFuture = ApiService().getAcceptedOrders();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _header(),
//               const SizedBox(height: 16),
//               _tabs(),
//               const SizedBox(height: 20),
//               Expanded(child: _orderList()),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _header() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: const [
//         Text(
//           "My Ordebbrs",
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//         Icon(Icons.search, color: Colors.grey),
//       ],
//     );
//   }

//   Widget _tabs() {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Row(
//         children: [_tabButton("On-going", 0), _tabButton("Completed", 1)],
//       ),
//     );
//   }

//   Widget _tabButton(String text, int index) {
//     final isSelected = selectedTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => selectedTab = index),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.white : Colors.transparent,
//             borderRadius: BorderRadius.circular(26),
//           ),
//           child: Center(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: isSelected ? Colors.black : Colors.grey,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _orderList() {
//     return FutureBuilder<List<dynamic>?>(
//       future: ordersFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError || snapshot.data == null) {
//           return const Center(child: Text("Failed to load orders"));
//         }

//         final orders = snapshot.data!;

//         if (orders.isEmpty) {
//           return const Center(child: Text("No orders found"));
//         }

//         // ✅ FILTER BASED ON TAB
//         final filteredOrders = orders.where((order) {
//           final status = order["shipment_status"]?["status"];
//           return selectedTab == 0
//               ? status !=
//                     "delivered" // On-going
//               : status == "delivered"; // Completed
//         }).toList();

//         if (filteredOrders.isEmpty) {
//           return Center(
//             child: Text(
//               selectedTab == 0 ? "No ongoing orders" : "No completed orders",
//             ),
//           );
//         }

//         return ListView.separated(
//           itemCount: filteredOrders.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 16),
//           itemBuilder: (context, index) {
//             final order = filteredOrders[index];
//             return _orderCardFromApi(order);
//           },
//         );
//       },
//     );
//   }

//   Widget _orderCardFromApi(Map<String, dynamic> order) {
//     final shipmentStatus = order["shipment_status"]?["status"] ?? "pending";
//     final pickupNo = order["pickup_no"] ?? "N/A";
//     final productName = order["product_details"]?["name"] ?? "Product";
//     // final createdAt = order["created_at"] ?? "";

//     Color statusColor;
//     String statusText;

//     switch (shipmentStatus) {
//       case "picked_up":
//         statusText = "IN TRANSIT";
//         statusColor = Colors.blue;
//         break;
//       case "delivered":
//         statusText = "DELIVERED";
//         statusColor = Colors.green;
//         break;
//       default:
//         statusText = "SEARCHING";
//         statusColor = Colors.orange;
//     }

//     return _card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _topRow(pickupNo, statusText, statusColor),
//           const SizedBox(height: 10),
//           Text(
//             productName,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const SizedBox(height: 14),

//           if (shipmentStatus == "pending")
//             _infoBox("Status", "Looking for carrier"),

//           if (shipmentStatus == "picked_up")
//             _infoBox(
//               "Tracking No",
//               order["shipment_status"]?["carrier_tracking_no"] ?? "-",
//             ),

//           if (shipmentStatus == "delivered")
//             _infoBox(
//               "Delivered At",
//               order["shipment_status"]?["delivered_at"] ?? "-",
//             ),

//           const SizedBox(height: 14),

//           Row(
//             children: [
//               _secondaryButton("Details"),
//               const SizedBox(width: 12),
//               if (shipmentStatus != "delivered") _primaryButton("Track Order"),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _card({required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }

//   Widget _topRow(String id, String status, Color color) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text("ID: $id", style: const TextStyle(color: Colors.grey)),
//         _statusChip(status, color),
//       ],
//     );
//   }

//   Widget _statusChip(String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(color: color, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _infoBox(String title, String value) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Row(
//         children: [
//           Text("$title  ", style: const TextStyle(color: Colors.grey)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _primaryButton(String text) {
//     return Expanded(
//       child: ElevatedButton(
//         onPressed: () {},
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 14),
//         ),
//         child: Text(text),
//       ),
//     );
//   }

//   Widget _secondaryButton(String text) {
//     return Expanded(
//       child: OutlinedButton(
//         onPressed: () {},
//         style: OutlinedButton.styleFrom(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 14),
//         ),
//         child: Text(text),
//       ),
//     );
//   }
// }
