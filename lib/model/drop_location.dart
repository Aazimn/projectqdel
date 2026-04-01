// lib/model/drop_location_model.dart
class DropLocation {
  final int id;
  final String address;
  final String? landmark;
  final String zipCode;
  final double latitude;
  final double longitude;
  final LocationDetails locationDetails;
  final UserDetails userDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  DropLocation({
    required this.id,
    required this.address,
    this.landmark,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.locationDetails,
    required this.userDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DropLocation.fromJson(Map<String, dynamic> json) {
    return DropLocation(
      id: json['id'],
      address: json['address'] ?? '',
      landmark: json['landmark'],
      zipCode: json['zip_code'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      locationDetails: LocationDetails.fromJson(json['location_details'] ?? {}),
      userDetails: UserDetails.fromJson(json['user_details'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class LocationDetails {
  final String district;
  final String state;
  final String country;

  LocationDetails({
    required this.district,
    required this.state,
    required this.country,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    return LocationDetails(
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class UserDetails {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String shopName;
  final String shopCategory;

  UserDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.shopName,
    required this.shopCategory,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      shopName: json['shop_name'] ?? '',
      shopCategory: json['shop_category'] ?? '',
    );
  }
}