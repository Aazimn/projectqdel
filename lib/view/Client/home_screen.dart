import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/view/Client/all_recentOrders.dart';
import 'package:projectqdel/view/Client/order_adding.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickActions(context),
                  const SizedBox(height: 24),
                  const Text(
                    "Active Orders",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _orderCard(
                    orderId: "QDEL10231",
                    status: "IN TRANSIT",
                    color: Colors.orange,
                  ),
                  _orderCard(
                    orderId: "QDEL10212",
                    status: "DELIVERED",
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔴 Header
  Widget _header() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffE53935), Color(0xffF0625F)],
        ),
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
            child: Icon(Icons.person, color: Colors.red, size: 32),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Welcome 👋", style: TextStyle(color: Colors.white70)),
              Text(
                "User",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.notifications, color: Colors.white),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionCard(
          icon: Icons.add_box,
          label: "Create Order",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddShipmentScreen()),
            );
          },
        ),
        _actionCard(
          icon: Icons.list_alt,
          label: "My Orders",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyOrdersScreen()),
            );
          },
        ),
        _actionCard(icon: Icons.local_shipping, label: "Track", onTap: () {}),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: ColorConstants.red, size: 30),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard({
    required String orderId,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
