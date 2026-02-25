class SenderDetails {
  final int id;
  final String fullName;
  final String email;
  final String phone;

  SenderDetails({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory SenderDetails.fromJson(Map<String, dynamic> json) {
    return SenderDetails(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}