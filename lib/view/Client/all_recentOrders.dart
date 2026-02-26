import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int _selectedTab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tabs(),
                  // const SizedBox(height: 20),
                  Expanded(
                    child: _selectedTab == 0
                        ? _ongoingOrders()
                        : _completedOrders(),
                  ),
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
        // border: BoxBorder.all(color: ColorConstants.red),
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

  Widget _ongoingOrders() {
    return ListView(
      children: [
        _ongoingOrderCard(),
        const SizedBox(height: 20),
        _inTransitCard(),
      ],
    );
  }

  Widget _completedOrders() {
    return ListView(
      children: [
        const Text(
          "COMPLETED ORDERS",
          style: TextStyle(letterSpacing: 1.5, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        _completedOrderCard(
          orderId: "#SHP-77210992",
          date: "Delivered yesterday",
        ),

        const SizedBox(height: 12),

        _completedOrderCard(
          orderId: "#SHP-77211045",
          date: "Delivered 2 days ago",
        ),
      ],
    );
  }

  Widget _completedOrderCard({required String orderId, required String date}) {
    return _card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xffE7F7EF),
                child: Icon(Icons.check, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffE7F7EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "DELIVERED",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 110,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        const Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "My Orders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ongoingOrderCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orderHeader(
            icon: Icons.inventory_2,
            title: "Premium Electronics Kit",
            orderId: "ORDER #92834012",
            status: "SEARCHING",
            statusColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _infoTile(
            Icons.schedule,
            "Estimated Pickup",
            "Today, within 15 mins",
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Details"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Track Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inTransitCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orderHeader(
            icon: Icons.local_shipping,
            title: "Mechanical Toolset",
            orderId: "ORDER #88210344",
            status: "IN TRANSIT",
            statusColor: Colors.blue,
          ),
          const SizedBox(height: 14),
          const Text(
            "DELIVERY PROGRESS",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Expanded(child: LinearProgressIndicator(value: 0.65)),
              SizedBox(width: 10),
              Text("65%", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EXPECTED ARRIVAL",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Tomorrow, 10:00 AM",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Color(0xffEEF2F7),
                child: Icon(Icons.map, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
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
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontSize: 12),
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
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
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
        border: BoxBorder.all(color: ColorConstants.red),
      ),
      child: child,
    );
  }
}
