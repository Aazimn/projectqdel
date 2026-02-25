// import 'package:flutter/material.dart';
// import 'package:projectqdel/view/Client/all_recentOrders.dart';
// import 'package:projectqdel/view/Client/home_screen.dart';
// import 'package:projectqdel/view/Client/order_adding.dart';
// import 'package:projectqdel/view/user_settings.dart';

// class UserDashboard extends StatefulWidget {
//   const UserDashboard({super.key});

//   @override
//   State<UserDashboard> createState() => _UserDashboardState();
// }

// class _UserDashboardState extends State<UserDashboard> {
//   int _currentIndex = 0;

//   final List<Widget> _pages = const [
//     HomeScreen(),
//     AddShipmentScreen(),
//     MyOrdersScreen(),
//     UserSettings(),
//   ];

//   @override
//   void setState(VoidCallback fn) {
//     // TODO: implement setState
//     super.setState(fn);
//     _currentIndex = widget.initialIndex;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_currentIndex],

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Colors.red,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:projectqdel/view/Client/all_recentOrders.dart';
import 'package:projectqdel/view/Client/home_screen.dart';
import 'package:projectqdel/view/Client/order_adding.dart';
import 'package:projectqdel/view/user_settings.dart';

class UserDashboard extends StatefulWidget {
  final int initialIndex;

  const UserDashboard({super.key, this.initialIndex = 0});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(), // index 0
    AddShipmentScreen(), // index 1
    MyOrdersScreen(), // index 2
    UserSettings(), // index 3
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // ✅ correct place
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
