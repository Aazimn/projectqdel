import 'package:flutter/material.dart';
import 'package:projectqdel/view/Client/all_recentOrders.dart';
import 'package:projectqdel/view/Client/client_settings.dart';
import 'package:projectqdel/view/Client/home_screen.dart';
import 'package:projectqdel/view/Client/order_adding.dart';

class ClientDashboard extends StatefulWidget {
  final int initialIndex;
  const ClientDashboard({super.key, this.initialIndex = 0});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    AddShipmentScreen(),
    MyOrdersScreen(),
    ClientSettings(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
