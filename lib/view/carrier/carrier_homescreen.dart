import 'package:flutter/material.dart';

class CarrierHomeScreen extends StatelessWidget {
  const CarrierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello Carrier 👋",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Ready for today's deliveries?",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.red),
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
                  _infoCard("Today's Deliveries", "12", Icons.local_shipping),
                  _infoCard("Completed", "7", Icons.check_circle),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Earnings",
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "₹1,250",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quickButton(Icons.list_alt, "Orders"),
                  _quickButton(Icons.map, "Map"),
                  _quickButton(Icons.history, "History"),
                  _quickButton(Icons.support_agent, "Support"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Deliveries",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.inventory, color: Colors.white),
                      ),
                      title: Text("Order #20${index + 1}"),
                      subtitle: const Text("Destination: Ernakulam"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.red,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    );
  }
}
