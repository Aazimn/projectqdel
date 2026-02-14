import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  ApiService apiService = ApiService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      body: Center(
        child: Text(
          "Home",
          style: TextStyle(fontSize: 30, color: Colors.white),
        ),
      ),
    );
  }
}
