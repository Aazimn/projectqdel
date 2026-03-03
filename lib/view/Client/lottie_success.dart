import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';

class OrderSuccessWrapper extends StatefulWidget {
  final int? productId;
  final int? pickupId;
  final String? orderNumber;

  const OrderSuccessWrapper({
    super.key,
    this.productId,
    this.pickupId,
    this.orderNumber,
  });

  @override
  State<OrderSuccessWrapper> createState() => _OrderSuccessWrapperState();
}

class _OrderSuccessWrapperState extends State<OrderSuccessWrapper> {
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
      MaterialPageRoute(builder: (_) => const ClientDashboard(initialIndex: 2)),
    );
  }

  Widget _successLottie() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie_assets/successful.json', repeat: false),
          const SizedBox(height: 20),
          const Text(
            "Order Placed Successfully!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (widget.orderNumber != null) ...[
            const SizedBox(height: 10),
            Text(
              "Order #${widget.orderNumber}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            "Redirecting to My Orders...",
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
