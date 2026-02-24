// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:projectqdel/model/order_payload.dart';
// import 'package:projectqdel/services/api_service.dart';
// import 'package:projectqdel/view/Client/order_placing.dart';
// import 'order_sucess.dart';

// class OrderPlacingScreen extends StatefulWidget {
//   final OrderPayload payload;
//   const OrderPlacingScreen({super.key, required this.payload});

//   @override
//   State<OrderPlacingScreen> createState() => _OrderPlacingScreenState();
// }

// class _OrderPlacingScreenState extends State<OrderPlacingScreen> {
//   final ApiService apiService = ApiService();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _processOrder();
//     });
//   }

//   Future<void> _processOrder() async {
//     try {
//       final productSuccess = await apiService.addProduct(
//         name: widget.payload.productName,
//         description: widget.payload.description,
//         volume: widget.payload.volume,
//         actualWeight: widget.payload.weight,
//         image: widget.payload.image,
//       );

//       if (!productSuccess) throw "Product creation failed";

//       final addressId = await apiService.addSenderAddress(
//         address: widget.payload.senderAddress,
//         phone: widget.payload.senderPhone,
//         landmark: widget.payload.senderLandmark,
//         district: widget.payload.senderDistrictId,
//         state: widget.payload.senderStateId,
//         country: widget.payload.senderCountryId,
//         zipCode: widget.payload.senderZip,
//       );

//       if (addressId == null) throw "Sender address failed";

//       final receiverSuccess = await apiService.addReceiverAddress(
//         productId: apiService.lastCreatedProductId!,
//         receiverId: apiService.currentUserId!,
//         receiverPhone: widget.payload.receiverPhone,
//         address: widget.payload.receiverAddress,
//         landmark: widget.payload.receiverLandmark,
//         district: widget.payload.receiverDistrictId,
//         state: widget.payload.receiverStateId,
//         country: widget.payload.receiverCountryId,
//         zipCode: widget.payload.receiverZip,
//       );

//       if (!receiverSuccess) throw "Receiver failed";

//       if (!mounted) return;

//       // 🛑 IMPORTANT: allow last animation frame to render
//       await Future.delayed(const Duration(milliseconds: 300));

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               OrderPlacedScreen(productId: apiService.lastCreatedProductId!),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(e.toString())));

//       // ❌ DO NOT POP → causes black screen
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Lottie.asset(
//               'assets/lottie_assets/delivery.json',
//               height: 180,
//               repeat: true,
//               animate: true,
//               frameRate: FrameRate.max,
//               errorBuilder: (_, __, ___) => const CircularProgressIndicator(),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Placing your order...",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Please wait while we process your shipment",
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
