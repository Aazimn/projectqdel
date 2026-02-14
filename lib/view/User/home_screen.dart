import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: IconButton(
          onPressed: () {
            ApiService.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SplashScreen()),
            );
          },
          icon: Icon(Icons.logout, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}
