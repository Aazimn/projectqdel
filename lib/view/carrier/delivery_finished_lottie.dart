import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';

class DeliveryFinishedLottie extends StatefulWidget {
  const DeliveryFinishedLottie({super.key});

  @override
  State<DeliveryFinishedLottie> createState() => _DeliveryFinishedLottieState();
}

class _DeliveryFinishedLottieState extends State<DeliveryFinishedLottie> {
  bool showSuccessAnimation = true;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const CarrierDashboard(initialIndex: 2),
      ),
    );
  }

  Widget _successLottie() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie_assets/delivery_done.json',
            repeat: false,
          ),
          const SizedBox(height: 20),
          const Text(
            "Order Completed Successfully!",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: _successLottie());
  }
}
