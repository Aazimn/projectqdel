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
    this.latitude,
    this.longitude,
    this.droppedAt,
    this.updatedAt,
  });

  // Helper method to parse custom date format
  static DateTime? _parseCustomDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // Try parsing the custom format first: "10 Apr 2026, 10:28 AM"
      return DateFormat('dd MMM yyyy, hh:mm a').parse(dateStr);
    } catch (e) {
      // Fallback to ISO format if custom format fails
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('⚠️ Failed to parse date: $dateStr');
        return null;
      }
    }
  }

  factory CompletedOrder.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null ? json['data'] as Map<String, dynamic> : json;
    
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
      latitude: data['latitude'] as String?,
      longitude: data['longitude'] as String?,
      droppedAt: _parseCustomDate(data['dropped_at'] as String?),
      updatedAt: _parseCustomDate(data['updated_at'] as String?),
    );
  }
}