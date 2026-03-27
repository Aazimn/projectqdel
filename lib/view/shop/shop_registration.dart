import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/model/shop_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/edit_order.dart';
import 'package:projectqdel/view/Client/map_picker.dart';
import 'package:projectqdel/view/Carrier/status_pending.dart';

class ShopRegistrationScreen extends StatefulWidget {
  final ShopRegistrationData registrationData;
  const ShopRegistrationScreen({super.key, required this.registrationData});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  File? shopPhoto;
  File? shopDocument;
  File? ownerPhoto;
  bool uploading = false;
  late final bool isExistingUser;

  List categories = [];
  bool isLoadingCategories = true;
  int? selectedCategoryId;

  final TextEditingController shopNameController = TextEditingController();
  // final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  final picker = ImagePicker();
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    logger.i("🏪 Shop Registration Screen Opened");
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final data = await ApiService().getShopCategories();

      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    shopNameController.dispose();
    // ownerNameController.dispose();
    addressController.dispose();
    landmarkController.dispose();

    zipCodeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      // logger.i(
      //   "📸 Opening image picker: $source for ${isPhoto ? 'photo' : 'document'}",
      // );

      final picked = await picker.pickImage(source: source, imageQuality: 70);

      if (picked != null) {
        final file = File(picked.path);

        logger.i("✅ Image selected");
        logger.i("📂 File path: ${picked.path}");
        logger.i("📦 File size: ${await file.length()} bytes");

        setState(() {
          if (type == "shop") {
            shopPhoto = file;
          } else if (type == "document") {
            shopDocument = file;
          } else if (type == "owner") {
            ownerPhoto = file;
          }
        });
      } else {
        logger.w("⚠️ User cancelled image selection");
      }
    } catch (e) {
      logger.e("❌ Error picking image: $e");
    }
  }

  Future<void> submitShop() async {
    logger.i("🚀 Submit Shop Button Pressed");

    // Validate required fields
    if (shopNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter shop name")));
      return;
    }

    // if (ownerNameController.text.isEmpty) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text("Please enter owner name")));
    //   return;
    // }

    if (addressController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter address")));
      return;
    }

    if (landmarkController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter landmark")));
      return;
    }

    if (zipCodeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter zip code")));
      return;
    }

    if (shopPhoto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please upload shop photo")));
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select shop category")),
      );
      return;
    }

    if (shopDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload shop document")),
      );
      return;
    }

    if (ownerPhoto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please upload owner photo")));
      return;
    }

    if (selectedCountry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select country")));
      return;
    }

    if (selectedState == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select state")));
      return;
    }

    if (selectedDistrict == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select district")));
      return;
    }

    logger.i("📄 Shop photo and document ready for upload");
    logger.i("📂 Shop photo path: ${shopPhoto!.path}");
    logger.i("📂 Shop document path: ${shopDocument!.path}");

    logger.i("📊 SHOP REGISTRATION DATA");
    logger.i("🏪 Shop Name: ${shopNameController.text}");
    // logger.i("👨‍💼 Owner Name: ${ownerNameController.text}");
    logger.i("📍 Address: ${addressController.text}");
    logger.i("🗺️ Landmark: ${landmarkController.text}");
    logger.i("📮 Zip Code: ${zipCodeController.text}");
    logger.i("📍 Latitude: ${latitudeController.text}");
    logger.i("📍 Longitude: ${longitudeController.text}");

    setState(() => uploading = true);

    final apiService = ApiService();
    bool success = false;

    try {
      if (!widget.registrationData.isExistingUser) {
        /// 🆕 NEW USER → FULL REGISTRATION
        logger.i("🆕 New user → shopRegistration");

        success = await apiService.shopRegistration(
          phone: widget.registrationData.phone,
          firstname: widget.registrationData.firstname,
          lastname: widget.registrationData.lastname,
          email: widget.registrationData.email,
          userType: widget.registrationData.userType,
          parcelResponsibilityAccepted:
              widget.registrationData.parcelResponsibilityAccepted,
          damageLossAccepted: widget.registrationData.damageLossAccepted,
          payoutTermsAccepted: widget.registrationData.payoutTermsAccepted,
          shopCategory: selectedCategoryId,
          shopcountryId: selectedCountryId,
          shopstateId: selectedStateId,
          shopdistrictId: selectedDistrictId,
          shopName: shopNameController.text,
          shopPhoto: shopPhoto!,
          shopDocument: shopDocument!,
          ownerShopPhoto: ownerPhoto!,
          address: addressController.text,
          landmark: landmarkController.text,
          districtId: widget.registrationData.districtId,
          stateId: widget.registrationData.stateId,
          countryId: widget.registrationData.countryId,
          zipCode: zipCodeController.text,
          latitude: latitudeController.text.isNotEmpty
              ? double.tryParse(latitudeController.text)
              : null,
          longitude: longitudeController.text.isNotEmpty
              ? double.tryParse(longitudeController.text)
              : null,
        );
      } else {
        /// 🔁 EXISTING USER → UPGRADE TO SHOP
        logger.i("🔁 Existing user → registerShopHandler");

        success = await apiService.registerShopHandler(
          shopName: shopNameController.text,
          shopCategory: selectedCategoryId!,
          address: addressController.text,
          landmark: landmarkController.text,
          zipCode: zipCodeController.text,
          latitude: latitudeController.text.isNotEmpty
              ? double.tryParse(latitudeController.text)
              : null,
          longitude: longitudeController.text.isNotEmpty
              ? double.tryParse(longitudeController.text)
              : null,
          country: selectedCountryId!,
          state: selectedStateId!,
          district: selectedDistrictId!,
          shopPhoto: shopPhoto!,
          shopDocument: shopDocument!,
          ownerPhoto: ownerPhoto!,
        );
      }

      logger.i("📡 API Response: $success");
    } catch (e, stack) {
      logger.e("❌ Upload error", error: e, stackTrace: stack);
    }

    if (!mounted) return;

    setState(() => uploading = false);

    if (success) {
      logger.i("✅ Shop registered successfully");

      await ApiService.setFirstTime(false);
      await ApiService.setUserType("shop");

      logger.i("➡️ Navigating to Shop Status Pending screen");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => StatusPending(phone: widget.registrationData.phone, userType: 'shop',)),
        (_) => false,
      );
    } else {
      logger.e("❌ Shop registration failed");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Shop registration failed")));
    }
  }

  void _showImageSourceSheet(String type) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, type);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, type);
              },
            ),
          ],
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
              "SHOP REGISTRATION",
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // TextField(
                  //   controller: ownerNameController,
                  //   decoration: const InputDecoration(
                  //     labelText: "Owner Name",
                  //     border: OutlineInputBorder(),
                  //     prefixIcon: Icon(Icons.person),
                  //   ),
                  // ),
                  // const SizedBox(height: 15),
                  TextField(
                    controller: shopNameController,
                    decoration: const InputDecoration(
                      labelText: "Shop Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),

                  const SizedBox(height: 15),

                  isLoadingCategories
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: "Shop Category",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: categories.map<DropdownMenuItem<int>>((item) {
                            return DropdownMenuItem<int>(
                              value: item['id'],
                              child: Text(item['name'] ?? "No Name"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                        ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerScreen(
                            initialLatitude: latitudeController.text.isNotEmpty
                                ? double.tryParse(latitudeController.text)
                                : null,
                            initialLongitude:
                                longitudeController.text.isNotEmpty
                                ? double.tryParse(longitudeController.text)
                                : null,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          latitudeController.text = result['latitude']
                              .toString();
                          longitudeController.text = result['longitude']
                              .toString();
                          addressController.text = result['locationName'];
                        });
                      }
                      if (latitudeController.text.isNotEmpty &&
                          longitudeController.text.isNotEmpty) {
                        Text(
                          "Lat: ${latitudeController.text}, Lng: ${longitudeController.text}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              latitudeController.text.isEmpty
                                  ? "Select Location from Map"
                                  : "Location Selected ✅",
                              style: TextStyle(
                                color: latitudeController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: landmarkController,
                    decoration: const InputDecoration(
                      labelText: "Landmark",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: zipCodeController,
                    decoration: const InputDecoration(
                      labelText: "Zip Code",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mail),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildLocationSelectorButtons(),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () => _showImageSourceSheet("document"),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: shopDocument == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text("Tap to upload Document photo"),
                                ],
                              ),
                            )
                          : Image.file(shopDocument!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Document Photo",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showImageSourceSheet("shop"),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: shopPhoto == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text("Tap to upload shop photo"),
                                ],
                              ),
                            )
                          : Image.file(shopPhoto!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Shop Photo",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () => _showImageSourceSheet("owner"),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ownerPhoto == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text("Tap to upload Owner photo"),
                                ],
                              ),
                            )
                          : Image.file(ownerPhoto!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Owner Photo",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  uploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: submitShop,
                          child: Text(
                            widget.registrationData.isExistingUser
                                ? "Submit for Approval"
                                : "Register Shop",
                          ),
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add these state variables with your existing controllers
  Map<String, dynamic>? selectedCountry;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;

  int? get selectedCountryId => selectedCountry?['id'];
  int? get selectedStateId => selectedState?['id'];
  int? get selectedDistrictId => selectedDistrict?['id'];

  // Add this method in your _ShopRegistrationScreenState class
  Widget _buildLocationSelectorButtons() {
    return Column(
      children: [
        // Country Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () async {
              final selected = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CountrySelector(
                  selectedId: selectedCountryId,
                  color: Colors.red,
                  onSelected: (country) async {
                    setState(() {
                      selectedCountry = country;
                      selectedState = null;
                      selectedDistrict = null;
                    });
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedCountry == null
                      ? Colors.red
                      : Colors.red.withOpacity(0.3),
                  width: selectedCountry == null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: selectedCountry == null ? Colors.red : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Country *",
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedCountry == null
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: selectedCountry == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          selectedCountry == null
                              ? "Select Country (Required)"
                              : selectedCountry!['name'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: selectedCountry == null
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: selectedCountry == null ? Colors.red : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),

        // State Selector
        if (selectedCountry != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                final selected =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => StateSelector(
                        selectedId: selectedStateId,
                        countryId: selectedCountryId!,
                        color: Colors.red,
                        onSelected: (state) async {
                          setState(() {
                            selectedState = state;
                            selectedDistrict = null;
                          });
                        },
                      ),
                    );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedState == null
                        ? Colors.red
                        : Colors.red.withOpacity(0.3),
                    width: selectedState == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: selectedState == null ? Colors.red : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "State *",
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedState == null
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: selectedState == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            selectedState == null
                                ? "Select State (Required)"
                                : selectedState!['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: selectedState == null
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: selectedState == null ? Colors.red : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // District Selector
        if (selectedState != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                final selected =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DistrictSelector(
                        selectedId: selectedDistrictId,
                        stateId: selectedStateId!,
                        color: Colors.red,
                        onSelected: (district) {
                          setState(() {
                            selectedDistrict = district;
                          });
                        },
                      ),
                    );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedDistrict == null
                        ? Colors.red
                        : Colors.red.withOpacity(0.3),
                    width: selectedDistrict == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: selectedDistrict == null ? Colors.red : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "District *",
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedDistrict == null
                                  ? Colors.red
                                  : Colors.grey[600],
                              fontWeight: selectedDistrict == null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            selectedDistrict == null
                                ? "Select District (Required)"
                                : selectedDistrict!['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: selectedDistrict == null
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: selectedDistrict == null ? Colors.red : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
