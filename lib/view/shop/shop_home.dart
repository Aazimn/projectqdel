import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_settings.dart';
import 'package:projectqdel/view/splash_screen.dart';

class ShopHome extends StatefulWidget {
  const ShopHome({super.key});

  @override
  State<ShopHome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<ShopHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shop Home ")),
      body: Column(
        children: [
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await ApiService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CarrierSettings()),
                (route) => false,
              );
            },
            child: const Text(
              "settings",
              style: TextStyle(color: ColorConstants.red),
            ),
          ),
        ],
      ),
    );
  }
}
