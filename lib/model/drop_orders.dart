import 'package:flutter/material.dart';

class ShopDropOrder {
  final int shopdropId;
  final String shopStatus;
  final String shopStatusDisplay;
  final String? image;
  final String dropCarrierName;
  final String dropCarrierPhone;
  final String dropCarrierTrackingNo;
  final String dropCarrierStatus;
  final String dropCarrierStatusDisplay;
  final String? nextCarrierName;
  final String? nextCarrierPhone;
  final String? nextCarrierTrackingNo;
  final String? nextCarrierStatus;
  final String? nextCarrierStatusDisplay;
  final int pickupId;
  final String pickupNo;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String productName;
  final String dropAssignedAt;
  final String arrivedAtShopAt;
  final String droppedAtShopAt;
  final String createdAt;

  ShopDropOrder({
    required this.shopdropId,
    required this.shopStatus,
    required this.shopStatusDisplay,
    this.image,
    required this.dropCarrierName,
    required this.dropCarrierPhone,
    required this.dropCarrierTrackingNo,
    required this.dropCarrierStatus,
    required this.dropCarrierStatusDisplay,
    this.nextCarrierName,
    this.nextCarrierPhone,
    this.nextCarrierTrackingNo,
    this.nextCarrierStatus,
    this.nextCarrierStatusDisplay,
    required this.pickupId,
    required this.pickupNo,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.productName,
    required this.dropAssignedAt,
    required this.arrivedAtShopAt,
    required this.droppedAtShopAt,
    required this.createdAt,
  });

  factory ShopDropOrder.fromJson(Map<String, dynamic> json) {
    return ShopDropOrder(
      shopdropId: json['shopdrop_id'] ?? 0,
      shopStatus: json['shop_status'] ?? '',
      shopStatusDisplay: json['shop_status_display'] ?? '',
      image: json['image'],
      dropCarrierName: json['drop_carrier_name'] ?? '',
      dropCarrierPhone: json['drop_carrier_phone'] ?? '',
      dropCarrierTrackingNo: json['drop_carrier_tracking_no'] ?? '',
      dropCarrierStatus: json['drop_carrier_status'] ?? '',
      dropCarrierStatusDisplay: json['drop_carrier_status_display'] ?? '',
      nextCarrierName: json['next_carrier_name'],
      nextCarrierPhone: json['next_carrier_phone'],
      nextCarrierTrackingNo: json['next_carrier_tracking_no'],
      nextCarrierStatus: json['next_carrier_status'],
      nextCarrierStatusDisplay: json['next_carrier_status_display'],
      pickupId: json['pickup_id'] ?? 0,
      pickupNo: json['pickup_no'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderPhone: json['sender_phone'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      receiverPhone: json['receiver_phone'] ?? '',
      receiverAddress: json['receiver_address'] ?? '',
      productName: json['product_name'] ?? '',
      dropAssignedAt: json['drop_assigned_at'] ?? '',
      arrivedAtShopAt: json['arrived_at_shop_at'] ?? '',
      droppedAtShopAt: json['dropped_at_shop_at'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get id => shopdropId.toString();
  String get status => shopStatus;
  String get carrierName => dropCarrierName;
  String get carrierPhone => dropCarrierPhone;
  String get trackingNo => dropCarrierTrackingNo;
  String get carrierStatus => dropCarrierStatus;
  String get updatedAt => createdAt;

  String getFormattedStatus() {
    switch (shopStatus) {
      case 'coming_to_shop':
        return 'Coming to Shop';
      case 'dropped_at_shop':
        return 'In Shop';
      case 'gone_from_shop':
        return 'Gone from Shop';
      case 'drop_assigned':
        return 'Drop Assigned';
      case 'arrived_at_shop':
        return 'Arrived at Shop';
      default:
        return shopStatusDisplay.isNotEmpty ? shopStatusDisplay : shopStatus.toUpperCase();
    }
  }

  Color getStatusColor() {
    switch (shopStatus) {
      case 'coming_to_shop':
      case 'drop_assigned':
      case 'arrived_at_shop':
        return Colors.orange;
      case 'dropped_at_shop':
        return Colors.blue;
      case 'gone_from_shop':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}