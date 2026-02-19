class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  final String approvalStatus;
  final String requestedAt;
  final String? document;

  final String userType;
  final int? countryId;
  final int? stateId;
  final int? districtId;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.approvalStatus,
    required this.requestedAt,
    this.document,

    required this.userType,
    this.countryId,
    this.stateId,
    this.districtId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',

      approvalStatus: json['approval_status'] ?? '',
      requestedAt: json['date_joined'] ?? '',
      document: json['document'],

      userType: json['user_type'] ?? 'client',
      countryId: json['country_id'],
      stateId: json['state_id'],
      districtId: json['district_id'],
    );
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? approvalStatus,
    String? requestedAt,
    String? document,
    String? userType,
    int? countryId,
    int? stateId,
    int? districtId,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      requestedAt: requestedAt ?? this.requestedAt,
      document: document ?? this.document,
      userType: userType ?? this.userType,
      countryId: countryId ?? this.countryId,
      stateId: stateId ?? this.stateId,
      districtId: districtId ?? this.districtId,
    );
  }

  bool get isCarrier => userType == "carrier";
  bool get isApproved => approvalStatus == "approved";
  bool get isPending => approvalStatus == "pending";
  bool get isRejected => approvalStatus == "rejected";
  bool get hasUploadedDocs => document != null && document!.isNotEmpty;

}
