// lib/models/complaint_model.dart
class ComplaintModel {
  final int? pickupDetails;
  final String subject;
  final String description;
  final String? orderId;
  final String? complaintType; // Keep it optional

  ComplaintModel({
    this.pickupDetails,
    required this.subject,
    required this.description,
    this.orderId,
    this.complaintType, // Now optional
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (pickupDetails != null) data['pickup_details'] = pickupDetails;
    data['subject'] = subject;
    data['description'] = description;
    if (orderId != null) data['order_id'] = orderId;
    if (complaintType != null) data['complaint_type'] = complaintType; // Only add if not null
    return data;
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      pickupDetails: json['pickup_details'],
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      orderId: json['order_id'],
      complaintType: json['complaint_type'],
    );
  }
}