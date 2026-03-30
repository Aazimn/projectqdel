import 'package:flutter/material.dart';

class CarrierDocument {
  final int id;
  final String? document;
  final String? shopPhoto;
  final String? ownerShopPhoto;
  final String? shopDocument;
  final DateTime uploadedAt;

  CarrierDocument({
    required this.id,
    this.document,
    this.shopPhoto,
    this.ownerShopPhoto,
    this.shopDocument,
    required this.uploadedAt,
  });

  factory CarrierDocument.fromJson(Map<String, dynamic> json) {
    return CarrierDocument(
      id: json['id'],
      document: json['document'],
      shopPhoto: json['shop_photo'],
      ownerShopPhoto: json['owner_shop_photo'],
      shopDocument: json['shop_document'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  bool get hasCarrierDocument => document != null && document!.isNotEmpty;
}

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String userType;
  
  final String approvalStatus;  
  final String? shopApprovalStatus;  
  
  final String? country;
  final String? state;
  final String? district;
  
  final int? countryId;
  final int? stateId;
  final int? districtId;
  
  final String? shopName;
  final int? shopCategories;
  final String? shopPhoto;
  final String? shopDocument;
  final String? ownerShopPhoto;
  
  final CarrierDocument? carrierDocument;
  
  final String? document;
  
  final bool parcelResponsibilityAccepted;
  final bool damageLossAccepted;
  final bool payoutTermsAccepted;
  
  final Map<String, dynamic>? shopAddress;
  
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
    this.carrierDocument,
    this.document,
    required this.parcelResponsibilityAccepted,
    required this.damageLossAccepted,
    required this.payoutTermsAccepted,
    this.shopAddress,
    required this.requestedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    CarrierDocument? carrierDoc;
    if (json['carrier_document'] != null) {
      carrierDoc = CarrierDocument.fromJson(json['carrier_document']);
    }
    
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
      carrierDocument: carrierDoc,
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
    CarrierDocument? carrierDocument,
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
      carrierDocument: carrierDocument ?? this.carrierDocument,
      document: document ?? this.document,
      parcelResponsibilityAccepted: parcelResponsibilityAccepted ?? this.parcelResponsibilityAccepted,
      damageLossAccepted: damageLossAccepted ?? this.damageLossAccepted,
      payoutTermsAccepted: payoutTermsAccepted ?? this.payoutTermsAccepted,
      shopAddress: shopAddress ?? this.shopAddress,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  bool get isCarrier => userType == "carrier";
  bool get isShop => userType == "shop";
  bool get isClient => userType == "client";
  
  bool get isApproved => approvalStatus == "approved";
  bool get isPending => approvalStatus == "pending";
  bool get isRejected => approvalStatus == "rejected";
  
  bool get isShopApproved => shopApprovalStatus == "approved";
  bool get isShopPending => shopApprovalStatus == "pending";
  bool get isShopRejected => shopApprovalStatus == "rejected";
  
  bool get hasUploadedDocs {
    if (isCarrier) {
      return carrierDocument?.hasCarrierDocument ?? false;
    }
    return document != null && document!.isNotEmpty;
  }
  
  String? get carrierDocumentUrl => carrierDocument?.document;
  
  bool get hasShopDocuments {
  if (isShop) {
    if (shopPhoto != null && shopPhoto!.isNotEmpty &&
        shopDocument != null && shopDocument!.isNotEmpty &&
        ownerShopPhoto != null && ownerShopPhoto!.isNotEmpty) {
      return true;
    }
    if (carrierDocument != null) {
      return (carrierDocument!.shopPhoto != null && carrierDocument!.shopPhoto!.isNotEmpty) &&
             (carrierDocument!.shopDocument != null && carrierDocument!.shopDocument!.isNotEmpty) &&
             (carrierDocument!.ownerShopPhoto != null && carrierDocument!.ownerShopPhoto!.isNotEmpty);
    }
    return false;
  }
  return document != null && document!.isNotEmpty;
}

  
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