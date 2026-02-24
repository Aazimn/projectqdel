import 'dart:io';

class OrderPayload {
  final int userId;

  final String productName;
  final String description;
  final String volume;
  final String weight;
  final File? image;

  // Sender
  final String senderAddress;
  final String senderPhone;
  final String senderLandmark;
  final int senderDistrictId;
  final int senderStateId;
  final int senderCountryId;
  final String senderZip;

  // Receiver
  final String receiverAddress;
  final String receiverPhone;
  final String receiverLandmark;
  final int receiverDistrictId;
  final int receiverStateId;
  final int receiverCountryId;
  final String receiverZip;

  OrderPayload({
    required this.userId,
    required this.productName,
    required this.description,
    required this.volume,
    required this.weight,
    this.image,

    required this.senderAddress,
    required this.senderPhone,
    required this.senderLandmark,
    required this.senderDistrictId,
    required this.senderStateId,
    required this.senderCountryId,
    required this.senderZip,

    required this.receiverAddress,
    required this.receiverPhone,
    required this.receiverLandmark,
    required this.receiverDistrictId,
    required this.receiverStateId,
    required this.receiverCountryId,
    required this.receiverZip,
  });
}