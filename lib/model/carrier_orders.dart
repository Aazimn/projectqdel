import 'package:intl/intl.dart';

class CompletedOrder {
  final int id;
  final int pickupId;
  final String? senderName;
  final String senderPhone;
  final String status;
  final DateTime? pickedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final String? carrierTrackingNo;
  final String? pickupNumber;
  final String? deliveryMode;
  
  final String? senderAddress;
  final String? senderLandmark;
  final String? senderDistrict;
  final String? senderState;
  final String? senderCountry;
  final String? senderZipCode;
  
  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final String? receiverLandmark;
  final String? receiverDistrict;
  final String? receiverState;
  final String? receiverCountry;
  final String? receiverZipCode;
  
  final String? shopName;
  final String? shopOwnerName;
  final String? shopCategory;
  final Map<String, dynamic>? shopAddress;
  
  final DateTime? droppedAtShopAt;
  
  final String? latitude;
  final String? longitude;
  final DateTime? droppedAt;
  final DateTime? updatedAt;

  CompletedOrder({
    required this.id,
    required this.pickupId,
    this.senderName,
    required this.senderPhone,
    required this.status,
    this.pickedAt,
    this.deliveredAt,
    required this.createdAt,
    this.carrierTrackingNo,
    this.pickupNumber,
    this.deliveryMode,
    this.senderAddress,
    this.senderLandmark,
    this.senderDistrict,
    this.senderState,
    this.senderCountry,
    this.senderZipCode,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.receiverLandmark,
    this.receiverDistrict,
    this.receiverState,
    this.receiverCountry,
    this.receiverZipCode,
    this.shopName,
    this.shopOwnerName,
    this.shopCategory,
    this.shopAddress,
    this.droppedAtShopAt,
    this.latitude,
    this.longitude,
    this.droppedAt,
    this.updatedAt,
  });

  static DateTime? _parseCustomDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').parse(dateStr);
    } catch (e) {
      try {
        return DateFormat('dd MMM yyyy, hh:mm:ss a').parse(dateStr);
      } catch (e) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          print('⚠️ Failed to parse date: $dateStr');
          return null;
        }
      }
    }
  }

  factory CompletedOrder.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null ? json['data'] as Map<String, dynamic> : json;
    
    Map<String, dynamic>? parsedShopAddress;
    if (data['shop_address'] != null) {
      if (data['shop_address'] is Map<String, dynamic>) {
        parsedShopAddress = Map<String, dynamic>.from(data['shop_address']);
      } else if (data['shop_address'] is String) {
        try {
          parsedShopAddress = {'address': data['shop_address']};
        } catch (e) {
          print('⚠️ Failed to parse shop_address: $e');
        }
      }
    }
    
    return CompletedOrder(
      id: data['id'] as int,
      pickupId: data['pickup_id'] ?? data['id'] as int? ?? 0,
      senderPhone: data['sender_phone'] as String? ?? '',
      senderName: data['sender_name'] as String?,
      status: data['status'] as String? ?? 'unknown',
      pickedAt: _parseCustomDate(data['picked_at'] as String?),
      deliveredAt: _parseCustomDate(data['delivered_at'] as String?),
      createdAt: _parseCustomDate(data['created_at'] as String?) ?? DateTime.now(),
      carrierTrackingNo: data['carrier_tracking_no'] as String?,
      pickupNumber: data['pickup_number'] as String?,
      deliveryMode: data['delivery_mode'] as String?,
      senderAddress: data['sender_address'] as String?,
      senderLandmark: data['sender_landmark'] as String?,
      senderDistrict: data['sender_district'] as String?,
      senderState: data['sender_state'] as String?,
      senderCountry: data['sender_country'] as String?,
      senderZipCode: data['sender_zip_code'] as String?,
      receiverName: data['receiver_name'] as String?,
      receiverPhone: data['receiver_phone'] as String?,
      receiverAddress: data['receiver_address'] as String?,
      receiverLandmark: data['receiver_landmark'] as String?,
      receiverDistrict: data['receiver_district'] as String?,
      receiverState: data['receiver_state'] as String?,
      receiverCountry: data['receiver_country'] as String?,
      receiverZipCode: data['receiver_zip_code'] as String?,
      
      shopName: data['shop_name'] as String?,
      shopOwnerName: data['shop_owner_name'] as String?,
      shopCategory: data['shop_category'] as String?,
      shopAddress: parsedShopAddress,
      
      droppedAtShopAt: _parseCustomDate(data['dropped_at_shop'] as String?),
      
      latitude: data['latitude'] as String?,
      longitude: data['longitude'] as String?,
      droppedAt: _parseCustomDate(data['dropped_at'] as String?),
      updatedAt: _parseCustomDate(data['updated_at'] as String?),
    );
  }

    bool get hasDropDateTime {
    return isDroppedAtShop && droppedAtShopAt != null;
  }

  String getFormattedDropDateTime() {
    if (droppedAtShopAt == null) return 'Not dropped';
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    return '${dateFormat.format(droppedAtShopAt!)} at ${timeFormat.format(droppedAtShopAt!)}';
  }

  String getFormattedDeliveredDateTime() {
    if (deliveredAt == null) return 'Not delivered';
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    return '${dateFormat.format(deliveredAt!)} at ${timeFormat.format(deliveredAt!)}';
  }
  
  
  String getFormattedShopAddress() {
    if (shopAddress == null) return 'Not available';
    
    final address = shopAddress!['address'] as String?;
    final landmark = shopAddress!['landmark'] as String?;
    final district = shopAddress!['district'] as String?;
    final state = shopAddress!['state'] as String?;
    final country = shopAddress!['country'] as String?;
    final zipCode = shopAddress!['zip_code'] as String?;
    
    List<String> parts = [];
    if (address != null && address.isNotEmpty) parts.add(address);
    if (landmark != null && landmark.isNotEmpty) parts.add(landmark);
    
    List<String> locationParts = [];
    if (district != null && district.isNotEmpty) locationParts.add(district);
    if (state != null && state.isNotEmpty) locationParts.add(state);
    if (country != null && country.isNotEmpty) locationParts.add(country);
    if (zipCode != null && zipCode.isNotEmpty) locationParts.add(zipCode);
    
    if (locationParts.isNotEmpty) {
      parts.add(locationParts.join(', '));
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Not available';
  }
  

  String getDisplayStatus() {
    if (status == 'Dropped at Shop') {
      return 'Drop';
    }
    return status;
  }

  bool get isDroppedAtShop {
    return status == 'Dropped at Shop';
  }
  
  bool get isDelivered {
    return status == 'Delivered';
  }
}