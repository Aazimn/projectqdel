class ReceiverAddress {
  final int id;
  final String receiverName;
  final String phoneNumber;
  final String address;
  final String landmark;
  final String district;
  final String state;
  final String country;
  final String zipCode;
  final double? latitude;
  final double? longitude;

  ReceiverAddress({
    required this.id,
    required this.receiverName,
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

  factory ReceiverAddress.fromJson(Map<String, dynamic> json) {
    return ReceiverAddress(
      id: json['id'],
      receiverName: json['receiver_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zip_code'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}