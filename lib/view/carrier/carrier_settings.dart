import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/Client/client_profile.dart';
import 'package:projectqdel/view/splash_screen.dart';

class CarrierSettings extends StatefulWidget {
  const CarrierSettings({super.key});

  @override
  State<CarrierSettings> createState() => _CarrierSettingsState();
}

class _CarrierSettingsState extends State<CarrierSettings> {
  final ApiService apiService = ApiService();
  UserModel? user;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final api = ApiService();
    user = await api.getMyProfile();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 50),
            _profileCard(context),
            const SizedBox(height: 20),
            _buildSectionTitle("Dashboard"),
            const SizedBox(height: 10),
            _buildDashboardTiles(),
            const SizedBox(height: 20),
            _buildSectionTitle("Activities"),
            const SizedBox(height: 10),
            _buildActivitiesTiles(),
            const SizedBox(height: 20),
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
          height: 110,
          decoration: const BoxDecoration(
            color: ColorConstants.red,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 6),
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/image_assets/logo_qdel.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientProfile()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffFCE4EC), Color(0xffFFD9E4)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.red, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("My Profile", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      "View & edit personal details",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildGradientTile(
            icon: Icons.history,
            title: "Order History",
            subtitle: "Track completed deliveries",
            gradientColors: [Colors.white, Colors.red.withOpacity(0.5)],
            iconColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarrierDashboard(initialIndex: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildGradientTile(
            icon: Icons.notifications_none,
            title: "Notifications",
            subtitle: "Push notifications, alerts",
            gradientColors: [Colors.white, Colors.red.withOpacity(0.5)],
            iconColor: Colors.purple,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildGradientTile(
            icon: Icons.payment,
            title: "Payments",
            subtitle: "Payment methods, transactions",
            gradientColors: [Colors.white, Colors.red.withOpacity(0.5)],
            iconColor: Colors.green,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildGradientTile(
            icon: Icons.security,
            title: "Privacy & Security",
            subtitle: "Account security, privacy settings",
            gradientColors: [Colors.white, Colors.white],
            iconColor: Colors.indigo,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildGradientTile(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "FAQs, contact support",
            gradientColors: [Colors.white, Colors.red.withOpacity(0.5)],
            iconColor: Colors.teal,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildGradientTile(
            icon: Icons.logout_outlined,
            title: "Log Out",
            subtitle: "Ending your session will require you to log in again",
            gradientColors: [Colors.white, Colors.red.withOpacity(0.5)],
            iconColor: Colors.teal,
            onTap: () {
              _confirmLogout();
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await ApiService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: ColorConstants.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.grey),
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
