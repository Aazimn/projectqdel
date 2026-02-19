import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/splash_screen.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
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
      backgroundColor: Colors.amber,
      body: Center(
        child: Text(
          "Settings",
          style: TextStyle(fontSize: 30, color: Colors.white),
        ),
      ),
    );
  }
}
