class ReceiverDetails {
  final int id;
  final String fullName;
  final String email;
  final String phone;

  ReceiverDetails({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory ReceiverDetails.fromJson(Map<String, dynamic> json) {
    return ReceiverDetails(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}