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
    String phone = '';
    if (json['phone_number'] != null && json['phone_number'].toString().isNotEmpty) {
      phone = json['phone_number'].toString();
    } else if (json['receiver_phone'] != null && json['receiver_phone'].toString().isNotEmpty) {
      phone = json['receiver_phone'].toString();
    } else if (json['phone'] != null && json['phone'].toString().isNotEmpty) {
      phone = json['phone'].toString();
    }
    String addressText = '';
    if (json['address'] != null && json['address'].toString().isNotEmpty) {
      addressText = json['address'].toString();
    } else if (json['address_text'] != null && json['address_text'].toString().isNotEmpty) {
      addressText = json['address_text'].toString();
    }
    
    return ReceiverAddress(
      id: json['id'] ?? 0,
      receiverName: json['receiver_name'] ?? '',
      phoneNumber: phone,
      address: addressText,
      landmark: json['landmark'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zip_code']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiver_name': receiverName,
      'receiver_phone': phoneNumber,
      'address_text': address,
      'landmark': landmark,
      'district': district,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}