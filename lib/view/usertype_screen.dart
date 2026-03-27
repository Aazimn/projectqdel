import 'package:flutter/material.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/Carrier/carrier_upload.dart';
import 'package:projectqdel/view/Carrier/status_pending.dart';
import 'package:projectqdel/view/Carrier/approved_screen.dart';
import 'package:projectqdel/view/Carrier/rejected_screen.dart';
import 'package:projectqdel/view/registration_screen.dart';
import 'package:projectqdel/view/shop/shop_home.dart';
import 'package:projectqdel/view/splash_screen.dart';

class UsertypeScreen extends StatefulWidget {
  final UserModel currentUser;

  const UsertypeScreen({super.key, required this.currentUser});

  @override
  State<UsertypeScreen> createState() => _UsertypeScreenState();
}

class _UsertypeScreenState extends State<UsertypeScreen> {
  String selectedRole = "client";
  final ApiService apiService = ApiService();
  bool switchingRole = false;
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.currentUser;
    selectedRole = user.userType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(context),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "How will you use the app?",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Choose the role that best fits your needs.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // Client Card
                  _roleCard(
                    role: "client",
                    title: "Client",
                    subtitle: "I want to send a parcel",
                    description:
                        "Access on-demand delivery services for your personal or business items.",
                    icon: Icons.inventory_2_outlined,
                    isDefault: true,
                  ),

                  const SizedBox(height: 20),

                  // Carrier Card
                  _roleCard(
                    role: "carrier",
                    title: "Carrier",
                    subtitle: "I want to deliver",
                    description:
                        "Join our fleet and earn money by fulfilling delivery requests in your area.",
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Shop Card
                  _roleCard(
                    role: "shop",
                    title: "Shop Hub",
                    subtitle: "Order Transfer & Dispatch Center",
                    description:
                        "Manage order handovers and ensure seamless delivery completion.",
                    icon: Icons.store_outlined,
                  ),

                  const Spacer(),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: switchingRole ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE82C2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getButtonText(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (selectedRole) {
      case "client":
        return "Continue as Client";
      case "shop":
        return "Continue as Shop";
      case "carrier":
        return "Continue as Carrier";
      default:
        return "Continue";
    }
  }

  Future<void> _handleContinue() async {
    if (selectedRole == user.userType) {
      Navigator.pop(context);
      return;
    }

    switch (selectedRole) {
      case "client":
        _confirmClientSwitch();
        break;
      case "shop":
        _switchToShop();
        break;
      case "carrier":
        _checkCarrierStatusAndNavigate();
        break;
    }
  }

  Future<void> _switchToShop() async {
    setState(() => switchingRole = true);

    try {
      final success = await apiService.updateUserType("shop");

      if (!success) {
        setState(() => switchingRole = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to switch to shop")),
        );
        return;
      }

      await ApiService.setUserType("shop");

      setState(() => switchingRole = false);

      // Navigate to Shop Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => switchingRole = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _checkCarrierStatusAndNavigate() async {
    setState(() => switchingRole = true);

    try {
      final success = await apiService.updateUserType("carrier");

      if (!success) {
        setState(() => switchingRole = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to switch to carrier")),
        );
        return;
      }

      await ApiService.setUserType("carrier");

      final updatedUser = await apiService.getMyProfile();

      if (updatedUser == null) {
        setState(() => switchingRole = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load profile")));
        return;
      }

      setState(() {
        user = updatedUser;
        switchingRole = false;
      });

      final bool profileHasDocs =
          updatedUser.document != null && updatedUser.document!.isNotEmpty;

      bool apiHasDocs = false;
      try {
        apiHasDocs = await apiService.checkDocumentStatus();
      } catch (_) {}

      final storedHasDocs = await ApiService.getHasUploadedDocs() ?? false;

      final bool hasDocs = profileHasDocs || apiHasDocs || storedHasDocs;

      String status = updatedUser.approvalStatus.trim().toLowerCase();

      if (hasDocs && status.isEmpty) {
        try {
          final apiStatusRaw = await apiService.checkApprovalStatus();
          if (apiStatusRaw != null && apiStatusRaw.trim().isNotEmpty) {
            status = apiStatusRaw.trim().toLowerCase();
            await ApiService.setApprovalStatus(status);
          }
        } catch (_) {}
      }

      print("========= CARRIER FLOW DEBUG =========");
      print("User Type: ${updatedUser.userType}");
      print("Document: ${updatedUser.document}");
      print("Has Docs: $hasDocs");
      print("Approval Status: $status");
      print("======================================");

      if (!hasDocs) {
        print("➡️ NAVIGATE → Upload Screen");
        _navigateToUploadScreen();
        return;
      }

      if (status == "pending") {
        print("➡️ NAVIGATE → Pending Screen");
        _navigateToPendingScreen();
        return;
      }

      if (status == "approved") {
        final hasSeen = await apiService.hasUserSeenApprovalScreen();

        if (!hasSeen) {
          print("➡️ NAVIGATE → Approved Screen (first time - from server)");
          _navigateToApprovedScreen();
        } else {
          print(
            "➡️ NAVIGATE → Carrier Dashboard (already seen approved - from server)",
          );
          _navigateToApprovedScreen(goToDashboardOnly: true);
        }
        return;
      }

      if (status == "rejected") {
        print("➡️ NAVIGATE → Rejected Screen");
        _navigateToRejectedScreen();
        return;
      }

      print("➡️ NAVIGATE → Pending Screen (fallback with docs)");
      _navigateToPendingScreen();
    } catch (e) {
      setState(() => switchingRole = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _navigateToUploadScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CarrierUploadScreen(
          registrationData: CarrierRegistrationData(
            phone: user.phone,
            firstname: user.firstName,
            lastname: user.lastName,
            email: user.email,
            userType: "carrier",
            countryId: user.countryId,
            stateId: user.stateId,
            districtId: user.districtId,
            isExistingUser: true,
            parcelResponsibilityAccepted: true,
            damageLossAccepted: true,
            payoutTermsAccepted: true,
          ),
        ),
      ),
      (route) => false,
    );
  }

  void _navigateToPendingScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => StatusPending(phone: user.phone, userType: 'carrier'),
      ),
      (route) => false,
    );
  }

  void _navigateToApprovedScreen({bool goToDashboardOnly = false}) {
    if (goToDashboardOnly) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CarrierDashboard()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AccountApprovedScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToRejectedScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RejectedScreen()),
      (route) => false,
    );
  }

  void _confirmClientSwitch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Account Type"),
        content: const Text(
          "Do you want to switch to Client account?\n\n"
          "You will lose carrier/shop access and orders.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchToClient();
            },
            child: const Text(
              "Yes, Switch",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToClient() async {
    setState(() => switchingRole = true);

    final success = await apiService.updateUserType("client");

    setState(() => switchingRole = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to switch to client")),
      );
      return;
    }

    await ApiService.setUserType("client");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }

  Widget _roleCard({
    required String role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    bool isDefault = false,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFE82C2A) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFEFEF)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? const Color(0xFFE82C2A) : Colors.grey,
              ),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFE82C2A),
                size: 26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),

        Positioned(
          top: 45,
          left: 16,
          child: _circleButton(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 45,
          right: 16,
          child: _circleButton(Icons.more_horiz, () {}),
        ),
        const Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Select Your Role",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.red, size: 18),
      ),
    );
  }
}
