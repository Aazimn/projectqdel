import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/splash_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, left: 16, right: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    _dashboardCard(
                      icon: Icons.people,
                      title: "Users",
                      subtitle: "Manage users",
                      onTap: () {
                        // Navigator.push(...)
                      },
                    ),
                    _dashboardCard(
                      icon: Icons.approval,
                      title: "Approvals",
                      subtitle: "Pending requests",
                      onTap: () {},
                    ),
                    _dashboardCard(
                      icon: Icons.location_city,
                      title: "Locations",
                      subtitle: "Country / State / District",
                      onTap: () {},
                    ),
                    _dashboardCard(
                      icon: Icons.local_shipping,
                      title: "Orders",
                      subtitle: "All deliveries",
                      onTap: () {},
                    ),
                    _dashboardCard(
                      icon: Icons.settings,
                      title: "Settings",
                      subtitle: "Admin controls",
                      onTap: () {},
                    ),
                    _dashboardCard(
                      icon: Icons.logout,
                      title: "Logout",
                      subtitle: "Sign out",
                      color: Colors.red.shade50,
                      iconColor: Colors.red,
                      onTap: () {
                        ApiService.logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplashScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔴 Header
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffE53935), Color(0xffF0625F)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 20),
            Center(
              child: Text(
                "Admin Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                "Manage your platform",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧩 Dashboard Card
  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorConstants.red.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? ColorConstants.red,
                size: 26,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
