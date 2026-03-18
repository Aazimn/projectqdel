import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/admin_profile.dart';
import 'package:projectqdel/view/Admin/dashboard_screen.dart';
import 'package:projectqdel/view/splash_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        elevation: 0,
        title: const Text(
          "Admin Settings",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _sectionTitle("ACCOUNT"),
          _settingsCard(
            icon: Icons.person,
            title: "Profile",
            subtitle: "View & update admin profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
          ),

          // _settingsCard(
          //   icon: Icons.lock,
          //   title: "Change Password",
          //   subtitle: "Update login credentials",
          //   onTap: () {},
          // ),
          const SizedBox(height: 20),

          _sectionTitle("SYSTEM"),
          _settingsCard(
            icon: Icons.public,
            title: "Manage Countries, States, Districts",
            subtitle: "Add, update or delete",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(initialTab: 2),
                ),
              );
            },
          ),

          // _settingsCard(
          //   icon: Icons.map,
          //   title: "Manage States",
          //   subtitle: "State level configuration",
          //   onTap: () {},
          // ),
          // _settingsCard(
          //   icon: Icons.location_city,
          //   title: "Manage Districts",
          //   subtitle: "District level configuration",
          //   onTap: () {
          //   },
          // ),
          const SizedBox(height: 5),

          _settingsCard(
            icon: Icons.group,
            title: "User Directory",
            subtitle: "Approve or reject users",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(initialTab: 1),
                ),
              );
            },
          ),

          const SizedBox(height: 5),

          /// 🚪 Logout
          _settingsCard(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out from admin panel",
            isDestructive: true,
            onTap: () {
              _confirmLogout(context);
            },
          ),
        ],
      ),
    );
  }

  // -------------------- Widgets --------------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors
                        .grey //.withOpacity(.4)
                  : ColorConstants.grey,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(.15)
                      : ColorConstants.red.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : ColorConstants.red,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
