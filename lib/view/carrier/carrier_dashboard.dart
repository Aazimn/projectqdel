import 'package:flutter/material.dart';
import 'package:projectqdel/view/Carrier/carrier_homescreen.dart';
import 'package:projectqdel/view/Carrier/carrier_settings.dart';
import 'package:projectqdel/view/Carrier/map_screen_pickup.dart';
import 'package:projectqdel/view/Client/client_profile.dart';

class CarrierDashboard extends StatefulWidget {
  const CarrierDashboard({super.key});

  @override
  State<CarrierDashboard> createState() => _CarrierDashboardState();
}

class _CarrierDashboardState extends State<CarrierDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CarrierHomescreen(),
    CarrierMapScreen(),
    CarrierHomescreen(),
    CarrierSettings(),
  ];

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
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
