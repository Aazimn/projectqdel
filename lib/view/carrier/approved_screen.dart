import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/view/carrier/carrier_dashboard.dart';

class AccountApprovedScreen extends StatelessWidget {
  const AccountApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.verified, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "SYSTEM VERIFIED",
                    style: TextStyle(
                      color: Colors.black54,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  )
                ],
              ),
            ),

            const Spacer(),

            Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 70,
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Account\nApproved!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                "Welcome to the team! Your account is now active. Tap below to start your journey.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CarrierDashboard()),
                    (_) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.4),
                        Colors.green.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(color: ColorConstants.black),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.home, color: ColorConstants.black),
                      SizedBox(width: 10),
                      Text(
                        "Go to Home Screen",
                        style: TextStyle(
                          color: ColorConstants.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "READY TO EXPLORE",
              style: TextStyle(
                color: Colors.black38,
                letterSpacing: 3,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
