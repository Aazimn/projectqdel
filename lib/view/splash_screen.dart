import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/dashboard_screen.dart';
import 'package:projectqdel/view/Carrier/rejected_screen.dart';
import 'package:projectqdel/view/Carrier/status_pending.dart';
import 'package:projectqdel/view/Client/user_dashboard.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/login_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    splash();
  }

  Future<void> splash() async {
    await ApiService.loadSession();

    final token = ApiService.accessToken;
    final userType = ApiService.userType?.toLowerCase();
    String? status = ApiService.approvalStatus?.toLowerCase();

    if (userType == "carrier") {
      status = await ApiService().checkApprovalStatus();

      if (status != null) {
        await ApiService.setApprovalStatus(status);
      }
    }

    debugPrint("TOKEN=$token | TYPE=$userType | STATUS=$status");

    if (token == null || userType == null) {
      go(const LoginScreen());
      return;
    }

    switch (userType) {
      case "admin":
        go(const DashboardScreen());
        break;

      case "client":
        go(const UserDashboard());
        break;

      case "carrier":
        if (status == "approved") {
          go(const CarrierDashboard());
        } else if (status == "pending") {
          go(StatusPending(phone: ApiService.phone!));
        } else {
          go(const RejectedScreen());
        }
        break;

      default:
        go(const LoginScreen());
    }
  }

  void go(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  // void _go(Widget page) {
  //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  // }

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
