import 'dart:math';

import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';

class AccountApprovedScreen extends StatefulWidget {
  const AccountApprovedScreen({super.key});

  @override
  State<AccountApprovedScreen> createState() => _AccountApprovedScreenState();
}

class _AccountApprovedScreenState extends State<AccountApprovedScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      // Call the server-side API to mark approval screen as seen
      // This just does a POST with no body
      final success = await _apiService.markApprovalScreenSeen();

      if (!mounted) return;

      if (success) {
        // Successfully marked on server, navigate to dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CarrierDashboard()),
          (_) => false,
        );
      } else {
        // Even if API fails, we should still proceed
        // Cache locally as fallback
        await ApiService.setApprovalScreenSeen(true);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CarrierDashboard()),
          (_) => false,
        );

        // Show a non-blocking message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Welcome aboard! Your preference has been saved locally.",
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Error occurred, but we should still let the user proceed
      await ApiService.setApprovalScreenSeen(true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CarrierDashboard()),
        (_) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Welcome! (Offline mode: ${e.toString().substring(0, min(50, e.toString().length))})",
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  ),
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
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 70),
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
                onTap: _isLoading ? null : _handleContinue,
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
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
