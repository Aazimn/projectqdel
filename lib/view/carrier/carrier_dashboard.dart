import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/view/Carrier/carrier_homescreen.dart';
import 'package:projectqdel/view/Carrier/carrier_settings.dart';
import 'package:projectqdel/view/Carrier/dashboard.dart';
import 'package:projectqdel/view/Carrier/map_screen_pickup.dart';

class CarrierDashboard extends StatefulWidget {
  final int initialIndex;
  const CarrierDashboard({super.key,this.initialIndex = 0});

  @override
  State<CarrierDashboard> createState() => _CarrierDashboardState();
}

class _CarrierDashboardState extends State<CarrierDashboard> {
  late int _currentIndex ;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      CarrierHomeScreen(
        onNavigateToIndex: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const CarrierMapScreen(),
      const Dashboard(),
      const CarrierSettings(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: ColorConstants.red,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.offline_bolt_rounded),
            label: 'Orders',
          ),
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
