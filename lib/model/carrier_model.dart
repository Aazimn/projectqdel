class CarrierRegistrationData {
  final String phone;
  final String firstname;
  final String lastname;
  final String email;
  final String userType;
  final int? countryId;
  final int? stateId;
  final int? districtId;
  final bool isExistingUser;

  CarrierRegistrationData({
    required this.phone,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.userType,
    this.countryId,
    this.stateId,
    this.districtId,
    required this.isExistingUser,
  });
}
