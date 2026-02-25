import 'package:projectqdel/model/product_details.dart';
import 'package:projectqdel/model/receiver_address.dart';
import 'package:projectqdel/model/sender_address.dart';
import 'package:projectqdel/model/sender_details.dart';

class OrderModel {
  final int id;
  final int? pickupId;

  final ProductDetails? productDetails;
  final SenderDetails? senderDetails;
  final SenderAddress? senderAddress;
  final ReceiverDetails? receiverDetails;

  final String? receiverName;
  final String? receiverPhone;
  final String? addressText;
  final String? landmark;

  final int? district;
  final int? state;
  final int? country;
  final String? zipCode;

  final String? latitude;
  final String? longitude;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    this.pickupId,
    this.productDetails,
    this.senderDetails,
    this.senderAddress,
    this.receiverDetails,
    this.receiverName,
    this.receiverPhone,
    this.addressText,
    this.landmark,
    this.district,
    this.state,
    this.country,
    this.zipCode,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      pickupId: json['pickup_no'],

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

      receiverName: json['receiver_name'],
      receiverPhone: json['receiver_phone'],
      addressText: json['address_text'],
      landmark: json['landmark'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      zipCode: json['zip_code'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}