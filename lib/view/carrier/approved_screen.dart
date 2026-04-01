import 'dart:math';
import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/Shop/shop_dashboard.dart';

class AccountApprovedScreen extends StatefulWidget {
  final String? userType; 

  const AccountApprovedScreen({super.key, this.userType});

  @override
  State<AccountApprovedScreen> createState() => _AccountApprovedScreenState();
}

class _AccountApprovedScreenState extends State<AccountApprovedScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    await ApiService.loadSession();
    setState(() {
      _userType = widget.userType ?? ApiService.userType?.toLowerCase();
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      final success = await _apiService.markApprovalScreenSeen();

      if (!mounted) return;

      if (success) {
        _navigateToDashboard();
      } else {
        await ApiService.setApprovalScreenSeen(true);

        if (!mounted) return;

        _navigateToDashboard();

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

      await ApiService.setApprovalScreenSeen(true);

      _navigateToDashboard();

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

  void _navigateToDashboard() {
    final isShop = _userType == "shop";
    
    if (isShop) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ShopDashboard()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CarrierDashboard()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShop = _userType == "shop";
    final title = isShop ? "Shop\nApproved!" : "Account\nApproved!";
    final subtitle = isShop 
        ? "Welcome to the Qdel Shop Network! Your shop is now active. Tap below to start your journey."
        : "Welcome to the team! Your account is now active. Tap below to start your journey.";
    final buttonText = isShop ? "Go to Shop Dashboard" : "Go to Home Screen";
    final icon = isShop ? Icons.store : Icons.check;
    final gradientColors = isShop 
        ? [Colors.orange.withOpacity(0.4), Colors.orange.withOpacity(0.08)]
        : [Colors.green.withOpacity(0.4), Colors.green.withOpacity(0.08)];
    final progressColor = isShop ? Colors.orange : Colors.green;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isShop ? Icons.storefront : Icons.verified,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isShop ? "SHOP VERIFIED" : "SYSTEM VERIFIED",
                    style: const TextStyle(
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
                color: isShop ? Colors.orange : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: isShop 
                        ? Colors.orange.withOpacity(0.4)
                        : Colors.green.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 70),
            ),

            const SizedBox(height: 30),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                      colors: gradientColors,
                    ),
                    border: Border.all(color: ColorConstants.black),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isShop ? Icons.store : Icons.home,
                                color: ColorConstants.black,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                buttonText,
                                style: const TextStyle(
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
            Text(
              isShop ? "READY TO EXPLORE" : "READY TO EXPLORE",
              style: const TextStyle(
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