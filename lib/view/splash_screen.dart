import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/admin_screen.dart';
import 'package:projectqdel/view/User/home_screen.dart';
import 'package:projectqdel/view/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    splash();
  }

   Future<void> splash() async {
    await Future.delayed(const Duration(seconds: 2));

    await ApiService.loadSession();

    if (!mounted) return;

    if (ApiService.accessToken == null) {
      _go(const LoginScreen());
      return;
    }

    if (ApiService.isFirstTime == true) {
      _go(const LoginScreen());
      return;
    }

    if (ApiService.userType == "admin") {
      _go(const AdminScreen());
    } else {
      _go(const HomeScreen());
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/image_assets/qdel_splash.jpeg",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
