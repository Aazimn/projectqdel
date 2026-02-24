import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool uploading = false;

  final picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 70);

    if (picked != null) {
      setState(() {
        document = File(picked.path);
      });
    }
  }

  Future<void> submitCarrier() async {
    if (document == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please upload document")));
      return;
    }

    setState(() => uploading = true);

    final apiService = ApiService();

    final success = widget.registrationData.isExistingUser
        ? await apiService.upgradeToCarrier(
            document: document!,
            countryId: widget.registrationData.countryId,
            stateId: widget.registrationData.stateId,
            districtId: widget.registrationData.districtId,
          )
        : await apiService.registerCarrierWithDocument(
            phone: widget.registrationData.phone,
            firstname: widget.registrationData.firstname,
            lastname: widget.registrationData.lastname,
            email: widget.registrationData.email,
            userType: widget.registrationData.userType,
            countryId: widget.registrationData.countryId,
            stateId: widget.registrationData.stateId,
            districtId: widget.registrationData.districtId,
            document: document!,
          );

    setState(() => uploading = false);

    if (success) {
      if (!widget.registrationData.isExistingUser) {
        await ApiService.setFirstTime(false);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => StatusPending(phone: widget.registrationData.phone),
        ),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.registrationData.isExistingUser
                ? "Failed to submit carrier request"
                : "Registration failed",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          SizedBox(height: 80),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      height: 180,
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

  void _showImageSourceSheet() {
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
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

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.red, size: 18),
      ),
    );
  }
}
