import 'package:projectqdel/model/product_details.dart';
import 'package:projectqdel/model/receiver_address.dart';
import 'package:projectqdel/model/receiver_details.dart' hide ProductDetails;
import 'package:projectqdel/model/sender_address.dart';
import 'package:projectqdel/model/sender_details.dart';

class OrderModel {
  final int id;
  final String? pickupNo; // Changed from pickupId to match backend

  final ProductDetails? productDetails;
  final SenderDetails? senderDetails;
  final SenderAddress? senderAddress;
  final ReceiverDetails? receiverDetails;
  final ReceiverAddress? receiverAddress;

  final DateTime createdAt;

  OrderModel({
    required this.id,
    this.pickupNo, // Changed name
    this.productDetails,
    this.senderDetails,
    this.senderAddress,
    this.receiverDetails,
    this.receiverAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int, // Add type casting
      pickupNo: json['pickup_no'] as String?, // Changed variable name
      
      productDetails: json['product_details'] != null
          ? ProductDetails.fromJson(json['product_details'])
          : null,

      senderDetails: json['sender_details'] != null
          ? SenderDetails.fromJson(json['sender_details'])
          : null,

      senderAddress: json['sender_address'] != null
          ? SenderAddress.fromJson(json['sender_address'])
          : null,

      receiverDetails: json['receiver_details'] != null
          ? ReceiverDetails.fromJson(json['receiver_details'])
          : null,

      receiverAddress: json['receiver_address'] != null
          ? ReceiverAddress.fromJson(json['receiver_address'])
          : null,

      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}