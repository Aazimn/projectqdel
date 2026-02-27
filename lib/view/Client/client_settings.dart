import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/client_profile.dart';

class ClientSettings extends StatefulWidget {
  const ClientSettings({super.key});

  @override
  State<ClientSettings> createState() => _ClientSettingsState();
}

class _ClientSettingsState extends State<ClientSettings> {
  final ApiService apiService = ApiService();
  UserModel? user;
  Future<void> loadProfile() async {
    final api = ApiService();
    user = await api.getMyProfile();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 16),
            _profileCard(context),
            const SizedBox(height: 20),
            _dashboardCard(),
            const SizedBox(height: 20),
            _activitiesCard(),
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
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        const Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Settings",
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: BoxBorder.all(color: ColorConstants.black),
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xffFCE4EC),
              child: Icon(Icons.person, color: Colors.red, size: 30),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // user!.firstName,
                    "My Profile",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "View & edit personal details",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard() {
    return _card(
      title: "Dashboard",
      children: [
        _tile(Icons.local_shipping, "My Orders"),
        _tile(Icons.history, "Order History"),
        _tile(Icons.favorite_border, "Saved Addresses"),
      ],
    );
  }

  Widget _activitiesCard() {
    return _card(
      title: "Activities",
      children: [
        _tile(Icons.notifications_none, "Notifications"),
        _tile(Icons.payment, "Payments"),
        _tile(Icons.security, "Privacy & Security"),
        _tile(Icons.help_outline, "Help & Support"),
      ],
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: BoxBorder.all(color: ColorConstants.black),
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String text) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.red),
          title: Text(text),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        Divider(color: Colors.grey.shade200),
      ],
    );
  }
}
