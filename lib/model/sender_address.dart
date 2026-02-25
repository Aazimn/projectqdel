class SenderAddress {
  final int id;
  final String senderName;
  final String phoneNumber;
  final String address;
  final String landmark;
  final String district;
  final String state;
  final String country;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  SenderAddress({
    required this.id,
    required this.senderName,
    required this.phoneNumber,
    required this.address,
    required this.landmark,
    required this.district,
    required this.state,
    required this.country,
    required this.zipCode,
    this.latitude,
    this.longitude,
  });

  factory SenderAddress.fromJson(Map<String, dynamic> json) {
    return SenderAddress(
      id: json['id'],
      senderName: json['sender_name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      landmark: json['landmark'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      zipCode: json['zip_code'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}