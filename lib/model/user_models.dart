// class UserModel {
//   final int id;
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String phone;

//   final String approvalStatus;
//   final String requestedAt;
//   final String? document;

//   final String userType;
//   final int? countryId;
//   final int? stateId;
//   final int? districtId;

//   UserModel({
//     required this.id,
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     required this.phone,
//     required this.approvalStatus,
//     required this.requestedAt,
//     this.document,

//     required this.userType,
//     this.countryId,
//     this.stateId,
//     this.districtId,
//   });

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'],
//       firstName: json['first_name'] ?? '',
//       lastName: json['last_name'] ?? '',
//       email: json['email'] ?? '',
//       phone: json['phone'] ?? '',

//       approvalStatus: json['approval_status'] ?? '',
//       requestedAt: json['date_joined'] ?? '',
//       document: json['document'],

//       userType: json['user_type'] ?? 'client',
//       countryId: json['country_id'],
//       stateId: json['state_id'],
//       districtId: json['district_id'],
//     );
//   }

//   UserModel copyWith({
//     int? id,
//     String? firstName,
//     String? lastName,
//     String? email,
//     String? phone,
//     String? approvalStatus,
//     String? requestedAt,
//     String? document,
//     String? userType,
//     int? countryId,
//     int? stateId,
//     int? districtId,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       firstName: firstName ?? this.firstName,
//       lastName: lastName ?? this.lastName,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       approvalStatus: approvalStatus ?? this.approvalStatus,
//       requestedAt: requestedAt ?? this.requestedAt,
//       document: document ?? this.document,
//       userType: userType ?? this.userType,
//       countryId: countryId ?? this.countryId,
//       stateId: stateId ?? this.stateId,
//       districtId: districtId ?? this.districtId,
//     );
//   }

//   bool get isCarrier => userType == "carrier";
//   bool get isApproved => approvalStatus == "approved";
//   bool get isPending => approvalStatus == "pending";
//   bool get isRejected => approvalStatus == "rejected";
//   bool get hasUploadedDocs => document != null && document!.isNotEmpty;

// }

import 'package:flutter/material.dart';

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String userType;
  
  // Approval statuses
  final String approvalStatus;  // User approval status
  final String? shopApprovalStatus;  // Shop approval status (for shop users)
  
  // Location fields (as strings from API)
  final String? country;
  final String? state;
  final String? district;
  
  // Location IDs (for API calls)
  final int? countryId;
  final int? stateId;
  final int? districtId;
  
  // Shop specific fields
  final String? shopName;
  final int? shopCategories;
  final String? shopPhoto;
  final String? shopDocument;
  final String? ownerShopPhoto;
  final String? document;
  
  // Terms acceptance
  final bool parcelResponsibilityAccepted;
  final bool damageLossAccepted;
  final bool payoutTermsAccepted;
  
  // Address fields
  final Map<String, dynamic>? shopAddress;
  
  // Timestamps
  final String requestedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.userType,
    required this.approvalStatus,
    this.shopApprovalStatus,
    this.country,
    this.state,
    this.district,
    this.countryId,
    this.stateId,
    this.districtId,
    this.shopName,
    this.shopCategories,
    this.shopPhoto,
    this.shopDocument,
    this.ownerShopPhoto,
    this.document,
    required this.parcelResponsibilityAccepted,
    required this.damageLossAccepted,
    required this.payoutTermsAccepted,
    this.shopAddress,
    required this.requestedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['user_type'] ?? 'client',
      approvalStatus: json['approval_status'] ?? '',
      shopApprovalStatus: json['shop_approval_status'],
      country: json['country'],
      state: json['state'],
      district: json['district'],
      countryId: json['country_id'],
      stateId: json['state_id'],
      districtId: json['district_id'],
      shopName: json['shop_name'],
      shopCategories: json['shop_categories'],
      shopPhoto: json['shop_photo'],
      shopDocument: json['shop_document'],
      ownerShopPhoto: json['owner_shop_photo'],
      document: json['document'],
      parcelResponsibilityAccepted: json['parcel_responsibility_accepted'] ?? false,
      damageLossAccepted: json['damage_loss_accepted'] ?? false,
      payoutTermsAccepted: json['payout_terms_accepted'] ?? false,
      shopAddress: json['shop_address'],
      requestedAt: json['date_joined'] ?? '',
    );
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? userType,
    String? approvalStatus,
    String? shopApprovalStatus,
    String? country,
    String? state,
    String? district,
    int? countryId,
    int? stateId,
    int? districtId,
    String? shopName,
    int? shopCategories,
    String? shopPhoto,
    String? shopDocument,
    String? ownerShopPhoto,
    String? document,
    bool? parcelResponsibilityAccepted,
    bool? damageLossAccepted,
    bool? payoutTermsAccepted,
    Map<String, dynamic>? shopAddress,
    String? requestedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      shopApprovalStatus: shopApprovalStatus ?? this.shopApprovalStatus,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      countryId: countryId ?? this.countryId,
      stateId: stateId ?? this.stateId,
      districtId: districtId ?? this.districtId,
      shopName: shopName ?? this.shopName,
      shopCategories: shopCategories ?? this.shopCategories,
      shopPhoto: shopPhoto ?? this.shopPhoto,
      shopDocument: shopDocument ?? this.shopDocument,
      ownerShopPhoto: ownerShopPhoto ?? this.ownerShopPhoto,
      document: document ?? this.document,
      parcelResponsibilityAccepted: parcelResponsibilityAccepted ?? this.parcelResponsibilityAccepted,
      damageLossAccepted: damageLossAccepted ?? this.damageLossAccepted,
      payoutTermsAccepted: payoutTermsAccepted ?? this.payoutTermsAccepted,
      shopAddress: shopAddress ?? this.shopAddress,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  // Helper getters for status checks
  bool get isCarrier => userType == "carrier";
  bool get isShop => userType == "shop";
  bool get isClient => userType == "client";
  
  bool get isApproved => approvalStatus == "approved";
  bool get isPending => approvalStatus == "pending";
  bool get isRejected => approvalStatus == "rejected";
  
  bool get isShopApproved => shopApprovalStatus == "approved";
  bool get isShopPending => shopApprovalStatus == "pending";
  bool get isShopRejected => shopApprovalStatus == "rejected";
  
  bool get hasUploadedDocs => document != null && document!.isNotEmpty;
  
  bool get hasShopDocuments => 
      shopPhoto != null && 
      shopPhoto!.isNotEmpty &&
      shopDocument != null && 
      shopDocument!.isNotEmpty &&
      ownerShopPhoto != null && 
      ownerShopPhoto!.isNotEmpty;
  
  bool get hasShopAddress => shopAddress != null;
  
  String get displayName => "$firstName $lastName".trim();
  
  String get userTypeDisplay {
    switch (userType) {
      case "carrier":
        return "Carrier";
      case "shop":
        return "Shop";
      case "client":
        return "Client";
      default:
        return "User";
    }
  }
  
  String get approvalStatusDisplay {
    if (isShop && shopApprovalStatus != null) {
      switch (shopApprovalStatus) {
        case "approved":
          return "Shop Approved";
        case "pending":
          return "Shop Pending";
        case "rejected":
          return "Shop Rejected";
        default:
          return approvalStatus;
      }
    }
    
    switch (approvalStatus) {
      case "approved":
        return "Approved";
      case "pending":
        return "Pending";
      case "rejected":
        return "Rejected";
      default:
        return "Unknown";
    }
  }
  
  Color get approvalStatusColor {
    if (isShop && shopApprovalStatus != null) {
      switch (shopApprovalStatus) {
        case "approved":
          return Colors.green;
        case "pending":
          return Colors.orange;
        case "rejected":
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
    
    switch (approvalStatus) {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get locationDisplay {
    if (country != null && state != null && district != null) {
      return "$district, $state, $country";
    } else if (state != null && country != null) {
      return "$state, $country";
    } else if (country != null) {
      return country!;
    }
    return "Location not set";
  }
  
  String get shopAddressDisplay {
    if (shopAddress != null) {
      final address = shopAddress!['address'] ?? '';
      final landmark = shopAddress!['landmark'] ?? '';
      final zipCode = shopAddress!['zip_code'] ?? '';
      
      if (address.isNotEmpty) {
        return "$address${landmark.isNotEmpty ? ', $landmark' : ''}${zipCode.isNotEmpty ? ' - $zipCode' : ''}";
      }
    }
    return "Address not set";
  }
}
