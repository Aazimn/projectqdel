import 'package:flutter/material.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/dashboard_screen.dart';
import 'package:projectqdel/view/carrier/accepted_screen.dart';
import 'package:projectqdel/view/carrier/approved_screen.dart';
import 'package:projectqdel/view/carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/carrier/carrier_upload.dart';
import 'package:projectqdel/view/carrier/rejected_screen.dart';
import 'package:projectqdel/view/carrier/status_pending.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
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
        go(const ClientDashboard());
        break;

      case "carrier":
        final profile = await apiService.getMyProfile();

        final hasDocs = profile?.hasUploadedDocs ?? false;
        final status = profile?.approvalStatus.toLowerCase();

        final activeOrderId = await ApiService.getActiveOrder();
        final cachedOrder = await ApiService.getActiveOrderDetails();

        if (cachedOrder != null && cachedOrder.id == activeOrderId) {
          go(AcceptedOrderScreen(orderId: activeOrderId!, order: cachedOrder));
          return;
        }

        /// 1️⃣ No documents uploaded
        if (!hasDocs) {
          go(
            CarrierUploadScreen(
              registrationData: CarrierRegistrationData(
                phone: profile!.phone,
                firstname: profile.firstName,
                lastname: profile.lastName,
                email: profile.email,
                userType: "carrier",
                countryId: profile.countryId,
                stateId: profile.stateId,
                districtId: profile.districtId,
                isExistingUser: true,
              ),
            ),
          );
          return;
        }

        /// 2️⃣ Documents uploaded but waiting approval
        if (status == "pending") {
          go(StatusPending(phone: profile!.phone));
          return;
        }

        /// 3️⃣ Approved
        if (status == "approved") {
          go(const AccountApprovedScreen());
          return;
        }

        /// 4️⃣ Rejected
        if (status == "rejected") {
          go(const RejectedScreen());
          return;
        }

        /// fallback
        go(const CarrierDashboard());
        break;
    }
  }

  void go(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
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
