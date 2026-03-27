import 'dart:io';

class ShopRegistrationData {
  final String phone;
  final String firstname;
  final String lastname;
  final String email;
  final String userType;
  final int? countryId;
  final int? stateId;
  final int? districtId;
  final bool isExistingUser;
  final String? shopName;
  final int? shopCategory;
  final String? address;
  final String? landmark;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final int? shopcountryId;
  final int? shopstateId;
  final int? shopdistrictId;
  final bool parcelResponsibilityAccepted;
  final bool damageLossAccepted;
  final bool payoutTermsAccepted;

  final File? shopPhoto;
  final File? shopDocument;
  final File? ownerShopPhoto;

  ShopRegistrationData({
    required this.phone,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.userType,
    this.countryId,
    this.stateId,
    this.districtId,
    required this.isExistingUser,
    this.shopName,
    this.shopCategory,
    this.address,
    this.landmark,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.shopcountryId,
    this.shopdistrictId,
    this.shopstateId,
    required this.parcelResponsibilityAccepted,
    required this.damageLossAccepted,
    required this.payoutTermsAccepted,

    this.shopPhoto,
    this.shopDocument,
    this.ownerShopPhoto,
  });
}
