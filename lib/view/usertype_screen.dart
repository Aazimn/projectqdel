import 'package:flutter/material.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/carrier/carrier_upload.dart';
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

                  _roleCard(
                    role: "carrier",
                    title: "Carrier",
                    subtitle: "I want to deliver",
                    description:
                        "Join our fleet and earn money by fulfilling delivery requests in your area.",
                    icon: Icons.local_shipping_outlined,
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
                              selectedRole == "client"
                                  ? "Continue as Client"
                                  : "Continue as Carrier",
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

  Future<void> _handleContinue() async {
    if (selectedRole == user.userType) {
      Navigator.pop(context);
      return;
    }

    if (selectedRole == "client") {
      _confirmClientSwitch();
    } else {
      _confirmCarrierSwitch();
    }
  }

  void _confirmClientSwitch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Account Type"),
        content: const Text(
          "Do you want to switch to Client account?\n\n"
          "You will lose carrier access and orders.",
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

  void _confirmCarrierSwitch() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Account Type"),
        content: const Text(
          "Do you want to change your account to Carrier?\n\n"
          "You will need to upload documents for approval.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchToCarrier();
            },
            child: const Text(
              "Yes, Continue",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

Future<void> _switchToCarrier() async {
  setState(() => switchingRole = true);

  final profile = await apiService.getMyProfile();

  setState(() => switchingRole = false);

  if (profile == null) return;
  if (profile.isApproved) {

    if (!profile.isCarrier) {
      final success = await apiService.updateUserType("carrier");

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to switch to carrier")),
        );
        return;
      }

      await ApiService.setUserType("carrier");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    }

    return;
  }

  if (!profile.hasUploadedDocs) {
    _goToUpload();
    return;
  }

  if (profile.isPending) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your documents are under review")),
    );
    return;
  }

  if (profile.isRejected) {
    _goToUpload();
    return;
  }

  _goToUpload();
}


  void _goToUpload() {
    Navigator.push(
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
          ),
        ),
      ),
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
