import 'package:flutter/material.dart';

class ShopDropOrder {
  final int? shopdropId;
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
  final int? pickupId;
  final String pickupNo;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String productName;
  final String? dropAssignedAt;
  final String? arrivedAtShopAt;
  final String? droppedAtShopAt;
  final String? dispatchedFromShopAt;
  final String createdAt;

  ShopDropOrder({
    this.shopdropId,
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
    this.pickupId,
    required this.pickupNo,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress,
    required this.productName,
    this.dropAssignedAt,
    this.arrivedAtShopAt,
    this.droppedAtShopAt,
    this.dispatchedFromShopAt,
    required this.createdAt,
  });

  factory ShopDropOrder.fromJson(Map<String, dynamic> json) {
    return ShopDropOrder(
      shopdropId: json['shopdrop_id'] as int?,
      shopStatus: json['shop_status'] as String? ?? '',
      shopStatusDisplay: json['shop_status_display'] as String? ?? '',
      image: json['image'] as String?,
      dropCarrierName: json['drop_carrier_name'] as String? ?? '',
      dropCarrierPhone: json['drop_carrier_phone'] as String? ?? '',
      dropCarrierTrackingNo: json['drop_carrier_tracking_no'] as String? ?? '',
      dropCarrierStatus: json['drop_carrier_status'] as String? ?? '',
      dropCarrierStatusDisplay: json['drop_carrier_status_display'] as String? ?? '',
      nextCarrierName: json['next_carrier_name'] as String?,
      nextCarrierPhone: json['next_carrier_phone'] as String?,
      nextCarrierTrackingNo: json['next_carrier_tracking_no'] as String?,
      nextCarrierStatus: json['next_carrier_status'] as String?,
      nextCarrierStatusDisplay: json['next_carrier_status_display'] as String?,
      pickupId: json['pickup_id'] as int?,
      pickupNo: json['pickup_no'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderPhone: json['sender_phone'] as String? ?? '',
      receiverName: json['receiver_name'] as String? ?? '',
      receiverPhone: json['receiver_phone'] as String? ?? '',
      receiverAddress: json['receiver_address'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      dropAssignedAt: json['drop_assigned_at'] as String?,
      arrivedAtShopAt: json['arrived_at_shop_at'] as String?,
      droppedAtShopAt: json['dropped_at_shop_at'] as String?,
      dispatchedFromShopAt: json['dispatched_from_shop_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  
  int get id => shopdropId ?? 0;
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
      case 'dispatched_from_shop':
        return 'Dispatched';
      case 'drop_assigned':
        return 'Drop Assigned';
      case 'arrived_at_shop':
        return 'Arrived at Shop';
      default:
        return shopStatus.toUpperCase();
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
      case 'dispatched_from_shop':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}