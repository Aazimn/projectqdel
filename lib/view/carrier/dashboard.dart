import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Carrier Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Welcome back, Driver 🚚",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusCard("Pending", "8", Icons.pending_actions),
                _statusCard("Active", "3", Icons.local_shipping),
                _statusCard("Completed", "15", Icons.check_circle),
              ],
            ),
          ),

          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.list_alt, "Orders"),
                _quickAction(Icons.map, "Map"),
                _quickAction(Icons.history, "History"),
                _quickAction(Icons.person, "Profile"),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Today's Deliveries",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.local_shipping, color: Colors.white),
                    ),
                    title: Text("Order #10${index + 1}"),
                    subtitle: const Text("Pickup: Kochi"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String count, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(height: 5),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.red,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}
