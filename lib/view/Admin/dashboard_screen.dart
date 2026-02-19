import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';

import 'package:projectqdel/view/Admin/admin_screen.dart';
import 'package:projectqdel/view/Admin/country_screen.dart';
import 'package:projectqdel/view/Admin/admin_settings.dart';
import 'package:projectqdel/view/Admin/users_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminScreen(),
    AdminSettings(),
    UserDirectoryScreen(),
    CountryScreen(),
    AdminSettings(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: ColorConstants.red,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: ColorConstants.black,
          unselectedItemColor: ColorConstants.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.request_page_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_sharp),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_location_alt),
              label: 'Countries Edit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
