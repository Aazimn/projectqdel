class ComplaintModel {
  final int? pickupDetails;
  final String subject;
  final String description;
  final String? orderId;
  final String? complaintType; 

  ComplaintModel({
    this.pickupDetails,
    required this.subject,
    required this.description,
    this.orderId,
    this.complaintType, 
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (pickupDetails != null) data['pickup_details'] = pickupDetails;
    data['subject'] = subject;
    data['description'] = description;
    if (orderId != null) data['order_id'] = orderId;
    if (complaintType != null) data['complaint_type'] = complaintType; 
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