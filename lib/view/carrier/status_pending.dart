import 'package:flutter/material.dart';
import 'dart:async';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/approved_screen.dart';
import 'package:projectqdel/view/Carrier/rejected_screen.dart';
import 'package:projectqdel/core/constants/color_constants.dart';

class StatusPending extends StatefulWidget {
  final String phone;

  const StatusPending({super.key, required this.phone});

  @override
  State<StatusPending> createState() => _StatusPendingState();
}

class _StatusPendingState extends State<StatusPending> {
  Timer? statusTimer;
  final api = ApiService();



  @override
  void initState() {
    super.initState();
    startCheckingStatus();
  
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  void startCheckingStatus() {
    statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await ApiService.loadSession();
      final statusRaw = await api.checkApprovalStatus();

      if (statusRaw != null) {
        await ApiService.setApprovalStatus(statusRaw); 
      }

      if (!mounted) return;

      if (statusRaw == null) return;
      final status = statusRaw.trim().toLowerCase();

      print("LIVE STATUS => $status"); 
      if (status == "approved") {
        await ApiService.setApprovalStatus("approved");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AccountApprovedScreen()),
          (_) => false,
        );
      } else if (status == "rejected") {
        await ApiService.setApprovalStatus("rejected");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RejectedScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.close, color: ColorConstants.black),
                  ),
                  const Spacer(),
                  const Text(
                    "APPLICATION STATUS",
                    style: TextStyle(
                      color: ColorConstants.black,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Verification in\nProgress",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorConstants.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.red.withOpacity(0.15),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                  SizedBox(width: 10),
                  Text(
                    "Reviewing Documents",
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Your documents have been submitted. Our team is currently reviewing your profile. You will be notified once you are approved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorConstants.black,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.4),
                      Colors.red.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: ColorConstants.black),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.support_agent, color: ColorConstants.black),
                    SizedBox(width: 10),
                    Text(
                      "Contact Support",
                      style: TextStyle(
                        color: ColorConstants.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Estimated response time: 24-48 hours",
              style: TextStyle(color: ColorConstants.black, fontSize: 12),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
