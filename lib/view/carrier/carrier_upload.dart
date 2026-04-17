import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/status_pending.dart';

class CarrierUploadScreen extends StatefulWidget {
  final CarrierRegistrationData registrationData;

  const CarrierUploadScreen({super.key, required this.registrationData});

  @override
  State<CarrierUploadScreen> createState() => _CarrierUploadScreenState();
}

class _CarrierUploadScreenState extends State<CarrierUploadScreen> {
  File? document;
  File? carrierImage;
  bool uploading = false;

  final picker = ImagePicker();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    logger.i("📄 Carrier Upload Screen Opened");
    _logFlagState();
    _checkDocumentStatusFromServer();
  }

  Future<void> _logFlagState() async {
    final hasUploadedDocs = await ApiService.getHasUploadedDocs();
    final isFirstTime = await ApiService.isFirstTime;
    final approvalStatus = await ApiService.approvalStatus;

    logger.i("🔍 Flag State Check:");
    logger.i("  hasUploadedDocs: $hasUploadedDocs");
    logger.i("  isFirstTime: $isFirstTime");
    logger.i("  approvalStatus: $approvalStatus");
  }

  Future<void> _checkDocumentStatusFromServer() async {
    try {
      if (await ApiService.getHasUploadedDocs() == true) {
        logger.w("⚠️ Flag mismatch! Clearing local flag");
        await ApiService.setHasUploadedDocs(false);
      }
    } catch (e) {
      logger.e("Error checking document status: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      logger.i("📸 Opening image picker: $source");

      final picked = await picker.pickImage(source: source, imageQuality: 70);

      if (picked != null) {
        final file = File(picked.path);

        logger.i("✅ Image selected");
        logger.i("📂 File path: ${picked.path}");
        logger.i("📦 File size: ${await file.length()} bytes");

        setState(() {
          document = file;
        });
      } else {
        logger.w("⚠️ User cancelled image selection");
      }
    } catch (e) {
      logger.e("❌ Error picking image: $e");
    }
  }

  Future<void> submitCarrier() async {
    logger.i("🚀 Submit Carrier Button Pressed");

    if (document == null) {
      logger.w("❌ No document selected");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please upload document")));
      return;
    }

    if (carrierImage == null) {
      logger.w("❌ No carrier image selected");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload carrier image")),
      );
      return;
    }

    logger.i("📄 Document ready for upload");
    logger.i("📂 Document path: ${document!.path}");
    logger.i("🖼️ Carrier image ready for upload");
    logger.i("📂 Carrier image path: ${carrierImage!.path}");

    logger.i("📊 REGISTRATION DATA");
    logger.i("📱 Phone: ${widget.registrationData.phone}");
    logger.i("👤 First Name: ${widget.registrationData.firstname}");
    logger.i("👤 Last Name: ${widget.registrationData.lastname}");
    logger.i("📧 Email: ${widget.registrationData.email}");
    logger.i("🌍 Country ID: ${widget.registrationData.countryId}");
    logger.i("🏙 State ID: ${widget.registrationData.stateId}");
    logger.i("📍 District ID: ${widget.registrationData.districtId}");
    logger.i("🔁 Existing User: ${widget.registrationData.isExistingUser}");

    setState(() => uploading = true);

    final apiService = ApiService();
    bool success = false;

    try {
      if (!widget.registrationData.isExistingUser) {
        logger.i("📝 Registering carrier (with document and carrier image)...");
        success = await apiService.carrierRegistrationWithDocument(
          phone: widget.registrationData.phone,
          firstname: widget.registrationData.firstname,
          lastname: widget.registrationData.lastname,
          email: widget.registrationData.email,
          countryId: widget.registrationData.countryId,
          stateId: widget.registrationData.stateId,
          districtId: widget.registrationData.districtId,
          document: document!,
          carrierphoto: carrierImage!,
          parcelResponsibilityAccepted:
              widget.registrationData.parcelResponsibilityAccepted,
          damageLossAccepted: widget.registrationData.damageLossAccepted,
          payoutTermsAccepted: widget.registrationData.payoutTermsAccepted,
        );

        logger.i("📝 Carrier registration result: $success");
        if (!success) {
          throw Exception("Carrier registration failed");
        }
      } else {
        logger.i("🌐 Calling uploadCarrierDocument API...");

        success = await apiService.updateUserrRegistration(
          document: document,
          carrierPhoto: carrierImage,
        );
      }

      logger.i("📡 API Upload Response: $success");
    } catch (e, stack) {
      logger.e("❌ Upload error", error: e, stackTrace: stack);
    }

    if (!mounted) return;

    setState(() => uploading = false);

    if (success) {
      logger.i("✅ Documents uploaded successfully");
      await ApiService.setFirstTime(false);

      logger.i("➡️ Navigating to StatusPending screen");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => StatusPending(
            phone: widget.registrationData.phone,
            userType: "carrier",
          ),
        ),
        (_) => false,
      );
    } else {
      logger.e("❌ Upload failed");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Document upload failed")));
    }
  }

  Future<void> _pickCarrierImage(ImageSource source) async {
    try {
      logger.i("📸 Opening image picker for carrier image: $source");

      final picked = await picker.pickImage(source: source, imageQuality: 70);

      if (picked != null) {
        final file = File(picked.path);

        logger.i("✅ Carrier image selected");
        logger.i("📂 File path: ${picked.path}");
        logger.i("📦 File size: ${await file.length()} bytes");

        setState(() {
          carrierImage = file;
        });
      } else {
        logger.w("⚠️ User cancelled carrier image selection");
      }
    } catch (e) {
      logger.e("❌ Error picking carrier image: $e");
    }
  }

  void _showCarrierImageSourceSheet() {
    logger.i("📂 Showing carrier image source options");

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  logger.i("📷 Camera selected for carrier image");
                  _pickCarrierImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  logger.i("🖼 Gallery selected for carrier image");
                  _pickCarrierImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageSourceSheet() {
    logger.i("📂 Showing image source options");

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  logger.i("📷 Camera selected");
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  logger.i("🖼 Gallery selected");
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.red, size: 18),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          top: 45,
          left: 16,
          child: _circleButton(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
        ),
        const Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "UPLOAD DOCUMENT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i("🔄 CarrierUploadScreen rebuild");

    return Scaffold(
      body: Column(
        children: [
          _header(context),

          const SizedBox(height: 80),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
              
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: document == null
                          ? const Center(child: Text("Tap to upload document"))
                          : Image.file(document!, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: _showCarrierImageSourceSheet,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: carrierImage == null
                          ? const Center(
                              child: Text("Tap to upload carrier photo"),
                            )
                          : Image.file(carrierImage!, fit: BoxFit.cover),
                    ),
                  ),

                  const SizedBox(height: 30),

                  uploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: submitCarrier,
                          child: Text(
                            widget.registrationData.isExistingUser
                                ? "Submit for Approval"
                                : "Submit & Register",
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
