import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/lottie_success.dart';
import 'package:projectqdel/view/Client/map_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressColors {
  static const Color senderPrimary = Color.fromARGB(255, 236, 47, 47);
  static const Color senderLight = Color(0xFFE8F5E9);
  static const Color senderAccent = Color.fromARGB(255, 158, 29, 29);

  static const Color receiverPrimary = Color.fromARGB(255, 236, 47, 47);
  static const Color receiverLight = Color(0xFFE3F2FD);
  static const Color receiverAccent = Color.fromARGB(255, 158, 29, 29);

  static const Color surface = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  bool isSenderCompleted = false;
  bool isReceiverCompleted = false;
  List<Map<String, dynamic>> receiverAddressList = [];
  bool isReceiverLoading = false;
  List<Map<String, dynamic>> senderAddressList = [];
  bool isSenderLoading = false;
  int? selectedSenderAddressId;
  int? selectedReceiverAddressId;
  bool isCreatingShipment = false;

  // Add these variables with your other declarations
  String? senderLocationName;
  String? receiverLocationName;

  Future<void> _loadSenderAddresses() async {
    setState(() => isSenderLoading = true);

    try {
      final data = await apiService.getSenderAddresses();
      setState(() {
        senderAddressList = List<Map<String, dynamic>>.from(data.reversed);
      });
    } catch (e) {
      setState(() {
        senderAddressList = [];
      });
    }

    setState(() => isSenderLoading = false);
  }

  Future<void> _applySenderAddress(Map<String, dynamic> addr) async {
    selectedSenderAddressId = addr["id"];

    senderNameCtrl.text = addr["sender_name"] ?? "";
    debugPrint("Sender name now => ${senderNameCtrl.text}");
    senderPhoneCtrl.text = addr["phone_number"] ?? "";
    senderAddressCtrl.text = addr["address"] ?? "";
    senderLandmarkCtrl.text = addr["landmark"] ?? "";
    senderZipCtrl.text = addr["zip_code"] ?? "";

    senderLat = double.tryParse(addr["latitude"] ?? "");
    senderLng = double.tryParse(addr["longitude"] ?? "");

    senderCountryCtrl.text = addr["country"] ?? "";
    senderStateCtrl.text = addr["state"] ?? "";
    senderDistrictCtrl.text = addr["district"] ?? "";

    selectedCountryId = countries.firstWhere(
      (c) => c['name'] == addr["country"],
      orElse: () => null,
    )?['id'];

    if (selectedCountryId != null) {
      await _loadStates(selectedCountryId!);

      selectedStateId = states.firstWhere(
        (s) => s['name'] == addr["state"],
        orElse: () => null,
      )?['id'];

      if (selectedStateId != null) {
        await _loadDistricts(selectedStateId!);

        selectedDistrictId = districts.firstWhere(
          (d) => d['name'] == addr["district"],
          orElse: () => null,
        )?['id'];
      }
    }

    setState(() {
      isSenderCompleted = true;
    });
  }

  Future<void> _loadReceiverAddresses() async {
    setState(() => isReceiverLoading = true);

    try {
      final List<dynamic> data = await apiService.getReceiverAddresses();
      receiverAddressList = List<Map<String, dynamic>>.from(data.reversed);
    } catch (e) {
      debugPrint("Receiver list error: $e");
      receiverAddressList = [];
    }

    setState(() => isReceiverLoading = false);
  }

  Future<void> _applyReceiverAddress(Map<String, dynamic> addr) async {
    selectedReceiverAddressId = addr["id"];

    receiverNameCtrl.text = addr["receiver_name"] ?? "";
    debugPrint("Sender name now => ${receiverNameCtrl.text}");
    receiverPhoneCtrl.text = addr["receiver_phone"] ?? "";
    receiverAddressCtrl.text = addr["address_text"] ?? "";
    receiverLandmarkCtrl.text = addr["landmark"] ?? "";
    receiverZipCtrl.text = addr["zip_code"] ?? "";

    receiverLat = double.tryParse(addr["latitude"] ?? "");
    receiverLng = double.tryParse(addr["longitude"] ?? "");
    receiverCountryCtrl.text = addr["country"] ?? "";
    receiverStateCtrl.text = addr["state"] ?? "";
    receiverDistrictCtrl.text = addr["district"] ?? "";

    selectedReceiverCountryId = countries.firstWhere(
      (c) => c['name'] == addr["country"],
      orElse: () => null,
    )?['id'];

    if (selectedReceiverCountryId == null) return;

    await _loadReceiverStates(selectedReceiverCountryId!);

    selectedReceiverStateId = receiverStates.firstWhere(
      (s) => s['name'] == addr["state"],
      orElse: () => null,
    )?['id'];

    if (selectedReceiverStateId == null) return;

    await _loadReceiverDistricts(selectedReceiverStateId!);

    selectedReceiverDistrictId = receiverDistricts.firstWhere(
      (d) => d['name'] == addr["district"],
      orElse: () => null,
    )?['id'];

    setState(() {});
  }

  String get senderSummary =>
      "${senderNameCtrl.text}, ${senderDistrictCtrl.text}, ${senderStateCtrl.text}";

  String get receiverSummary =>
      "${receiverNameCtrl.text}, ${receiverDistrictCtrl.text}, ${receiverStateCtrl.text}";
  File? productImage;
  bool isInitializingDefaults = true;
  final picker = ImagePicker();
  bool isUserChangingCountry = false;
  bool isUserChangingState = false;

  double? senderLat;
  double? senderLng;

  double? receiverLat;
  double? receiverLng;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController volumeCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController senderNameCtrl = TextEditingController();

  final TextEditingController senderPhoneCtrl = TextEditingController();
  final TextEditingController senderAddressCtrl = TextEditingController();
  final TextEditingController senderLandmarkCtrl = TextEditingController();
  final TextEditingController senderDistrictCtrl = TextEditingController();
  final TextEditingController senderStateCtrl = TextEditingController();
  final TextEditingController senderCountryCtrl = TextEditingController();
  final TextEditingController senderZipCtrl = TextEditingController();

  final TextEditingController receiverNameCtrl = TextEditingController();
  final TextEditingController receiverPhoneCtrl = TextEditingController();
  final TextEditingController receiverAddressCtrl = TextEditingController();
  final TextEditingController receiverLandmarkCtrl = TextEditingController();
  final TextEditingController receiverZipCtrl = TextEditingController();
  final TextEditingController receiverDistrictCtrl = TextEditingController();
  final TextEditingController receiverStateCtrl = TextEditingController();
  final TextEditingController receiverCountryCtrl = TextEditingController();

  List<dynamic> countries = [];
  List<dynamic> states = [];
  List<dynamic> districts = [];

  int? selectedCountryId;
  int? selectedStateId;
  int? selectedDistrictId;

  bool isCountryLoading = false;
  bool isStateLoading = false;
  bool isDistrictLoading = false;

  List<dynamic> receiverStates = [];
  List<dynamic> receiverDistricts = [];

  int? selectedReceiverCountryId;
  int? selectedReceiverStateId;
  int? selectedReceiverDistrictId;

  bool isReceiverStateLoading = false;
  bool isReceiverDistrictLoading = false;

  final ApiService apiService = ApiService();

  Map<int, List> stateCache = {};
  Map<int, List> districtCache = {};

  int? savedCountryId;
  int? savedStateId;
  int? savedDistrictId;

  Future<void> _loadReceiverStates(int countryId) async {
    if (!stateCache.containsKey(countryId)) {
      stateCache[countryId] = await apiService.getStates(countryId: countryId);
    }

    final countryName = countries.firstWhere(
      (c) => c['id'] == countryId,
    )['name'];

    receiverStates = stateCache[countryId]!
        .where((s) => s['country'] == countryName)
        .toList();
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    if (!districtCache.containsKey(stateId)) {
      districtCache[stateId] = await apiService.getDistricts(stateId: stateId);
    }

    receiverDistricts = districtCache[stateId]!
        .where((d) => d['state'] == stateId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    isInitializingDefaults = true;

    final prefs = await SharedPreferences.getInstance();
    apiService.currentUserId = prefs.getInt('user_id');
    savedCountryId = prefs.getInt('country');
    savedStateId = prefs.getInt('state');
    savedDistrictId = prefs.getInt('district');

    debugPrint(
      "Saved IDs => country:$savedCountryId state:$savedStateId district:$savedDistrictId",
    );
    await _loadCountries();
    if (savedCountryId != null) {
      selectedCountryId = savedCountryId;
      final country = countries.firstWhere(
        (c) => c['id'] == savedCountryId,
        orElse: () => null,
      );
      if (country != null) {
        senderCountryCtrl.text = country['name'];
        await _loadStates(savedCountryId!);
      }
    }

    if (savedStateId != null) {
      selectedStateId = savedStateId;
      final state = states.firstWhere(
        (s) => s['id'] == savedStateId,
        orElse: () => null,
      );
      if (state != null) {
        senderStateCtrl.text = state['name'];
        await _loadDistricts(savedStateId!);
      }
    }
    if (savedDistrictId != null) {
      selectedDistrictId = savedDistrictId;
      final district = districts.firstWhere(
        (d) => d['id'] == savedDistrictId,
        orElse: () => null,
      );
      if (district != null) {
        senderDistrictCtrl.text = district['name'];
      }
    }
    selectedReceiverCountryId = selectedCountryId;
    selectedReceiverStateId = selectedStateId;
    selectedReceiverDistrictId = selectedDistrictId;
    receiverCountryCtrl.text = senderCountryCtrl.text;
    receiverStateCtrl.text = senderStateCtrl.text;
    receiverDistrictCtrl.text = senderDistrictCtrl.text;
    if (selectedReceiverCountryId != null) {
      await _loadReceiverStates(selectedReceiverCountryId!);
    }
    if (selectedReceiverStateId != null) {
      await _loadReceiverDistricts(selectedReceiverStateId!);
    }
    isInitializingDefaults = false;
    setState(() {});
  }

  Future<void> _loadCountries() async {
    setState(() => isCountryLoading = true);
    try {
      countries = await apiService.getCountries();
    } catch (e) {
      debugPrint("Country load error: $e");
    }
    setState(() => isCountryLoading = false);
  }

  Future<void> _loadStates(int countryId) async {
    isStateLoading = true;
    setState(() {});
    try {
      if (!stateCache.containsKey(0)) {
        stateCache[countryId] = await apiService.getStates(
          countryId: countryId,
        );
      }
      final countryName = countries.firstWhere(
        (c) => c['id'] == countryId,
      )['name'];
      states = stateCache[countryId]!
          .where((s) => s['country'] == countryName)
          .toList();
    } catch (e) {
      debugPrint("State load error: $e");
    }
    isStateLoading = false;
    setState(() {});
  }

  Future<void> _loadDistricts(int stateId) async {
    isDistrictLoading = true;
    setState(() {});
    try {
      if (!districtCache.containsKey(0)) {
        districtCache[stateId] = await apiService.getDistricts(
          stateId: stateId,
        );
      }
      districts = districtCache[stateId]!
          .where((d) => d['state'] == stateId)
          .toList();
    } catch (e) {
      debugPrint("District load error: $e");
    }
    isDistrictLoading = false;
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        productImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      bottomNavigationBar: _buildBottomButton(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            SizedBox(height: 30),
            _buildProductFieldsSection(),
            SizedBox(height: 10),

            _sectionHeader("SENDER ADDRESS"),
            isSenderCompleted
                ? _buildSavedAddressCard(
                    type: "Sender",
                    primaryColor: AddressColors.senderPrimary,
                    lightColor: AddressColors.senderLight,
                    name: senderNameCtrl.text,
                    phone: senderPhoneCtrl.text,
                    address: senderAddressCtrl.text,
                    landmark: senderLandmarkCtrl.text,
                    zip: senderZipCtrl.text,
                    district: senderDistrictCtrl.text,
                    state: senderStateCtrl.text,
                    country: senderCountryCtrl.text,
                    onEdit: _openAttractiveSenderSelectorSheet,
                    locationName: senderLocationName,
                    lat: senderLat,
                    lng: senderLng,
                  )
                : _buildAttractiveAddressCard(
                    title: "Sender Address",
                    subtitle: "Add pickup location details",
                    iconPath: "assets/sender_icon.png",
                    primaryColor: AddressColors.senderPrimary,
                    lightColor: AddressColors.senderLight,
                    onTap: _openAttractiveSenderSelectorSheet,
                  ),
            SizedBox(height: 10),

            _sectionHeader("RECEIVER ADDRESS"),
            isReceiverCompleted
                ? _buildSavedAddressCard(
                    type: "Receiver",
                    primaryColor: AddressColors.receiverPrimary,
                    lightColor: AddressColors.receiverLight,
                    name: receiverNameCtrl.text,
                    phone: receiverPhoneCtrl.text,
                    address: receiverAddressCtrl.text,
                    landmark: receiverLandmarkCtrl.text,
                    zip: receiverZipCtrl.text,
                    district: receiverDistrictCtrl.text,
                    state: receiverStateCtrl.text,
                    country: receiverCountryCtrl.text,
                    onEdit: _openAttractiveReceiverSelectorSheet,
                    locationName: receiverLocationName, // Add this
                    lat: receiverLat, // Add this
                    lng: receiverLng, // Add this
                  )
                : _buildAttractiveAddressCard(
                    title: "Receiver Address",
                    subtitle: "Add delivery location details",
                    iconPath: "assets/receiver_icon.png",
                    primaryColor: AddressColors.receiverPrimary,
                    lightColor: AddressColors.receiverLight,
                    onTap: _openAttractiveReceiverSelectorSheet,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              // borderRadius: BorderRadius.only(
              //   // Radius.circular(20),
              //   bottomRight: Radius.circular(20),
              //   topRight: Radius.circular(20),
              //   // bottomLeft: Radius.circular(20),
              // ),
              color: Colors.red,
            ),
            width: 170,
            padding: const EdgeInsets.all(14),

            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AddressColors
                  .senderPrimary, // Using sender primary color for label
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AddressColors.senderPrimary.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                color: AddressColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AddressColors.textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AddressColors.senderPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AddressColors.senderPrimary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.red.shade300,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                ),
                prefixIcon: _getPrefixIconForField(label),
                prefixIconColor: AddressColors.senderPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get appropriate icon for each field
  Widget? _getPrefixIconForField(String label) {
    IconData? iconData;

    switch (label.toLowerCase()) {
      case 'product name':
        iconData = Icons.drive_file_rename_outline;
        break;
      case 'description':
        iconData = Icons.description_outlined;
        break;
      case 'volume (cm³)':
        iconData = Icons.square_foot;
        break;
      case 'weight (kg)':
        iconData = Icons.fitness_center;
        break;
      default:
        iconData = Icons.edit;
    }

    return Icon(iconData, size: 20);
  }

  void _resetSenderForm() {
    senderNameCtrl.clear();
    senderPhoneCtrl.clear();
    senderAddressCtrl.clear();
    senderLandmarkCtrl.clear();
    senderZipCtrl.clear();

    senderLat = null;
    senderLng = null;

    selectedCountryId = savedCountryId;
    selectedStateId = savedStateId;
    selectedDistrictId = savedDistrictId;

    states.clear();
    districts.clear();

    if (savedCountryId != null) {
      senderCountryCtrl.text = countries.firstWhere(
        (c) => c['id'] == savedCountryId,
      )['name'];
    } else {
      senderCountryCtrl.clear();
    }

    senderStateCtrl.clear();
    senderDistrictCtrl.clear();
  }

  void _resetReceiverForm() {
    receiverNameCtrl.clear();
    receiverPhoneCtrl.clear();
    receiverAddressCtrl.clear();
    receiverLandmarkCtrl.clear();
    receiverZipCtrl.clear();

    receiverLat = null;
    receiverLng = null;

    selectedReceiverCountryId = savedCountryId;
    selectedReceiverStateId = savedStateId;
    selectedReceiverDistrictId = savedDistrictId;

    receiverStates.clear();
    receiverDistricts.clear();

    receiverCountryCtrl.text = senderCountryCtrl.text;
    receiverStateCtrl.clear();
    receiverDistrictCtrl.clear();
  }

  Widget _imageUploadBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product Image",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AddressColors.senderPrimary,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AddressColors.senderPrimary.withOpacity(0.3),
                  width: 1.5,
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AddressColors.senderPrimary.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: productImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: AddressColors.senderPrimary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload product photo",
                          style: TextStyle(
                            color: AddressColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        productImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFieldsSection() {
    return Column(
      children: [
        _input("Product Name", "e.g. iPhone 15 Pro Max", controller: nameCtrl),
        _input(
          "Description",
          "Briefly describe the contents...",
          controller: descCtrl,
          maxLines: 3,
        ),
        Row(
          children: [
            Expanded(
              child: _input(
                "Volume (cm³)",
                "0.00",
                controller: volumeCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            Expanded(
              child: _input(
                "Weight (kg)",
                "0.00",
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        _imageUploadBox(),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isCreatingShipment
            ? null
            : () async {
                if (nameCtrl.text.isEmpty ||
                    volumeCtrl.text.isEmpty ||
                    senderAddressCtrl.text.isEmpty ||
                    senderDistrictCtrl.text.isEmpty ||
                    senderStateCtrl.text.isEmpty ||
                    senderCountryCtrl.text.isEmpty ||
                    senderZipCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all required fields"),
                    ),
                  );
                  return;
                }
                final productSuccess = await apiService.addProduct(
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  volume: volumeCtrl.text,
                  actualWeight: weightCtrl.text,
                  image: productImage,
                );
                if (!productSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Product creation failed")),
                  );
                  return;
                }
                if (apiService.lastCreatedProductId == null ||
                    apiService.currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("User session error. Please login again"),
                    ),
                  );
                  return;
                }
                if (selectedReceiverCountryId == null ||
                    selectedReceiverStateId == null ||
                    selectedReceiverDistrictId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please select receiver country, state and district",
                      ),
                    ),
                  );
                  return;
                }
                if (senderLat == null || senderLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select pickup location on map"),
                    ),
                  );
                  return;
                }

                if (receiverLat == null || receiverLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select delivery location on map"),
                    ),
                  );
                  return;
                }
                if (selectedSenderAddressId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a sender address"),
                    ),
                  );
                  return;
                }

                if (selectedReceiverAddressId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a receiver address"),
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                setState(() => isCreatingShipment = true);

                final pickupResponse = await apiService.createPickupRequest(
                  receiverId: selectedReceiverAddressId!,
                  productId: apiService.lastCreatedProductId!,
                  senderAddressId: selectedSenderAddressId!,
                  receiverAddressId: selectedReceiverAddressId!,
                );

                setState(() => isCreatingShipment = false);

                if (pickupResponse == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to create shipment")),
                  );
                  return;
                }
                final pickupId = pickupResponse["id"];

                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderSuccessWrapper(
                      productId: apiService.lastCreatedProductId,
                      pickupId: pickupId,
                      orderNumber: pickupResponse["pickup_no"],
                    ),
                  ),
                );
              },
        child: isCreatingShipment
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Create Shipment",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 110,
          decoration: const BoxDecoration(
            color: ColorConstants.red,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          // child: Image.asset(
          //   "assets/image_assets/qdel_bike_1.jpeg",
          //   fit: BoxFit.cover,
          // ),
        ),
        Positioned(
          bottom: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 6),

                    color: Colors.white,
                  ),
                  child: Image.asset(
                    "assets/image_assets/logo_qdel.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  Widget apiDropdown({
    required String hint,
    required List<dynamic> items,
    required bool loading,
    required int? selectedId,
    required Function(dynamic) onChanged,
  }) {
    final hasValue =
        items.isNotEmpty &&
        selectedId != null &&
        items.any((e) => e['id'] == selectedId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: DropdownButtonFormField<int>(
        value: hasValue ? selectedId : null,
        isExpanded: true,
        hint: Text(hint),
        items: items
            .map<DropdownMenuItem<int>>(
              (item) => DropdownMenuItem<int>(
                value: item['id'],
                child: Text(item['name']),
              ),
            )
            .toList(),
        onChanged: loading || items.isEmpty
            ? null
            : (id) {
                final selectedItem = items.firstWhere((e) => e['id'] == id);
                onChanged(selectedItem);
              },
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xffEFF1F7),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildAttractiveAddressCard({
    required String title,
    required String subtitle,
    required String iconPath,
    required Color primaryColor,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AddressColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddressCard({
    required String type,
    required Color primaryColor,
    required Color lightColor,
    required String name,
    required String phone,
    required String address,
    required String landmark,
    required String zip,
    required String district,
    required String state,
    required String country,
    required VoidCallback onEdit,
    String? locationName, // Add this parameter
    double? lat, // Add these for coordinates
    double? lng,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "$type Address Saved",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildInfoRow(Icons.phone, phone, primaryColor),

                  // Address
                  _buildInfoRow(Icons.location_on, address, primaryColor),

                  // Landmark (if available)
                  if (landmark.isNotEmpty)
                    _buildInfoRow(Icons.landscape, landmark, primaryColor),

                  // ZIP Code
                  _buildInfoRow(Icons.pin_drop, zip, primaryColor),

                  const Divider(height: 24),

                  // Location Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // District, State, Country
                        _buildInfoRow(
                          Icons.map,
                          "$district, $state, $country",
                          primaryColor,
                          isBold: true,
                        ),

                        // Location Name (from map)
                        if (locationName != null && locationName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoRow(
                              Icons.location_pin,
                              locationName,
                              primaryColor,
                            ),
                          ),

                        // Coordinates (if location name not available)
                        if (lat != null &&
                            lng != null &&
                            (locationName == null || locationName.isEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoRow(
                              Icons.pin_drop,
                              "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}",
                              primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Edit Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit, color: primaryColor),
                      label: Text(
                        "Edit Address",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: AddressColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAttractiveSenderBottomSheet() {
    debugPrint('🚀 Opening sender bottom sheet');

    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext parentContext) {
        debugPrint('📱 Building sender bottom sheet content');

        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(
                    "Add Sender Address",
                    AddressColors.senderPrimary,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedInputField(
                            "Full Name",
                            "Enter sender's full name",
                            controller: senderNameCtrl,
                            icon: Icons.person_outline,
                            color: AddressColors.senderPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Phone Number",
                            "Enter phone number",
                            controller: senderPhoneCtrl,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            color: AddressColors.senderPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Street Address",
                            "Enter street address",
                            controller: senderAddressCtrl,
                            icon: Icons.home_outlined,
                            color: AddressColors.senderPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Landmark",
                            "Enter nearby landmark",
                            controller: senderLandmarkCtrl,
                            icon: Icons.landscape_outlined,
                            color: AddressColors.senderPrimary,
                          ),
                          _buildAnimatedInputField(
                            "ZIP Code",
                            "Enter ZIP code",
                            controller: senderZipCtrl,
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            color: AddressColors.senderPrimary,
                          ),
                          _buildMapSelectionCard(
                            "Pickup Location",
                            senderLat,
                            () async {
                              debugPrint('🗺️ Opening map picker');
                              final result = await Navigator.push(
                                sheetContext,
                                MaterialPageRoute(
                                  builder: (_) => const MapPickerScreen(),
                                ),
                              );

                              if (result != null) {
                                debugPrint(
                                  '📍 Selected: ${result['latitude']}, ${result['longitude']}',
                                );
                                debugPrint(
                                  '📍 Location name: ${result['locationName']}',
                                );

                                setModalState(() {
                                  senderLat = result['latitude'];
                                  senderLng = result['longitude'];
                                  senderLocationName = result['locationName'];
                                });
                              }
                            },
                            AddressColors.senderPrimary,
                            locationName: senderLocationName,
                          ),

                          const SizedBox(height: 16),

                          _buildLocationDropdowns(
                            setModalState,
                            isSender: true,
                          ),

                          const SizedBox(height: 24),
                          _buildAttractiveSaveButton(
                            color: AddressColors.senderPrimary,
                            onPressed: () async {
                              debugPrint('💾 Save sender pressed');

                              if (senderNameCtrl.text.isEmpty ||
                                  selectedDistrictId == null ||
                                  senderLat == null) {
                                _showErrorSnackBar(
                                  "Please complete all sender details",
                                );
                                return;
                              }

                              debugPrint('📡 Calling addSenderAddress API');

                              final addressId = await apiService
                                  .addSenderAddress(
                                    name: senderNameCtrl.text,
                                    phone: senderPhoneCtrl.text,
                                    address: senderAddressCtrl.text,
                                    landmark: senderLandmarkCtrl.text,
                                    district: selectedDistrictId!,
                                    state: selectedStateId!,
                                    country: selectedCountryId!,
                                    zipCode: senderZipCtrl.text,
                                    latitude: senderLat.toString(),
                                    longitude: senderLng.toString(),
                                  );

                              if (addressId == null) {
                                _showErrorSnackBar(
                                  "Failed to save sender address",
                                );
                                return;
                              }

                              debugPrint(
                                '✅ Address saved, closing sheet with ID: $addressId',
                              );
                              Navigator.of(sheetContext).pop(addressId);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((addressId) async {
      debugPrint('📱 Bottom sheet closed with value: $addressId');

      if (addressId == null || !mounted) return;

      setState(() {
        isSenderCompleted = true;
      });

      await _loadSenderAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sender address saved successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _openAttractiveReceiverBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(
                    "Add Receiver Address",
                    AddressColors.receiverPrimary,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        children: [
                          _buildAnimatedInputField(
                            "Full Name",
                            "Enter receiver's full name",
                            controller: receiverNameCtrl,
                            icon: Icons.person_outline,
                            color: AddressColors.receiverPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Phone Number",
                            "Enter phone number",
                            controller: receiverPhoneCtrl,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            color: AddressColors.receiverPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Street Address",
                            "Enter street address",
                            controller: receiverAddressCtrl,
                            icon: Icons.home_outlined,
                            color: AddressColors.receiverPrimary,
                          ),
                          _buildAnimatedInputField(
                            "Landmark",
                            "Enter nearby landmark",
                            controller: receiverLandmarkCtrl,
                            icon: Icons.landscape_outlined,
                            color: AddressColors.receiverPrimary,
                          ),
                          _buildAnimatedInputField(
                            "ZIP Code",
                            "Enter ZIP code",
                            controller: receiverZipCtrl,
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            color: AddressColors.receiverPrimary,
                          ),

                          _buildMapSelectionCard(
                            "Delivery Location",
                            receiverLat,
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MapPickerScreen(),
                                ),
                              );

                              if (result != null) {
                                setModalState(() {
                                  receiverLat = result['latitude'];
                                  receiverLng = result['longitude'];
                                  receiverLocationName = result['locationName'];
                                });
                              }
                            },
                            AddressColors.receiverPrimary,
                            locationName: receiverLocationName,
                          ),
                          const SizedBox(height: 16),

                          _buildLocationDropdowns(
                            setModalState,
                            isSender: false,
                          ),

                          const SizedBox(height: 24),

                          _buildAttractiveSaveButton(
                            onPressed: () async {
                              if (receiverNameCtrl.text.isEmpty ||
                                  selectedReceiverDistrictId == null ||
                                  receiverLat == null) {
                                _showErrorSnackBar(
                                  "Please complete all receiver details",
                                );
                                return;
                              }

                              final receiverAddressId = await apiService
                                  .addReceiverAddress(
                                    receiverName: receiverNameCtrl.text,
                                    receiverPhone: receiverPhoneCtrl.text,
                                    address: receiverAddressCtrl.text,
                                    landmark: receiverLandmarkCtrl.text,
                                    district: selectedReceiverDistrictId,
                                    state: selectedReceiverStateId,
                                    country: selectedReceiverCountryId,
                                    zipCode: receiverZipCtrl.text,
                                    latitude: receiverLat.toString(),
                                    longitude: receiverLng.toString(),
                                  );

                              if (receiverAddressId == null) {
                                _showErrorSnackBar(
                                  "Failed to save receiver address",
                                );
                                return;
                              }

                              selectedReceiverAddressId = receiverAddressId;
                              Navigator.pop(context);
                              setState(() {
                                isReceiverCompleted = true;
                              });
                              await _loadReceiverAddresses();
                            },
                            color: AddressColors.receiverPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAttractiveSenderSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(
                    "Select Sender Address",
                    AddressColors.senderPrimary,
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: apiService.getSenderAddresses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return _buildEmptyState(
                            "No saved addresses",
                            Icons.location_off,
                            AddressColors.senderPrimary,
                          );
                        }

                        final list = List<Map<String, dynamic>>.from(
                          snapshot.data!.reversed,
                        );

                        if (list.isEmpty) {
                          return _buildEmptyState(
                            "No saved addresses",
                            Icons.location_off,
                            AddressColors.senderPrimary,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final addr = list[index];
                            return _buildAttractiveAddressListItem(
                              addr: addr,
                              color: AddressColors.senderPrimary,
                              lightColor: AddressColors.senderLight,
                              onTap: () async {
                                await _applySenderAddress(addr);
                                setState(() {
                                  isSenderCompleted = true;
                                });
                                Navigator.pop(context);
                              },
                              onDelete: () async {
                                final confirm = await _showDeleteDialog(
                                  context,
                                );
                                if (confirm == true) {
                                  await apiService.deleteSenderAddress(
                                    addressId: addr["id"],
                                  );
                                  if (context.mounted) {
                                    modalSetState(() {});
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildAddNewButton(
                    "Add New Sender Address",
                    AddressColors.senderPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      _resetSenderForm();
                      _openAttractiveSenderBottomSheet();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAttractiveReceiverSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildSheetHeader(
                    "Select Receiver Address",
                    AddressColors.receiverPrimary,
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: apiService.getReceiverAddresses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return _buildEmptyState(
                            "No saved addresses",
                            Icons.location_off,
                            AddressColors.receiverPrimary,
                          );
                        }

                        final list = List<Map<String, dynamic>>.from(
                          snapshot.data!.reversed,
                        );

                        if (list.isEmpty) {
                          return _buildEmptyState(
                            "No saved addresses",
                            Icons.location_off,
                            AddressColors.receiverPrimary,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final addr = list[index];
                            return _buildAttractiveAddressListItem(
                              addr: addr,
                              color: AddressColors.receiverPrimary,
                              lightColor: AddressColors.receiverLight,
                              onTap: () async {
                                selectedReceiverAddressId = addr["id"];
                                await _applyReceiverAddress(addr);
                                setState(() {
                                  isReceiverCompleted = true;
                                });
                                Navigator.pop(context);
                              },
                              onDelete: () async {
                                final confirm = await _showDeleteDialog(
                                  context,
                                );
                                if (confirm == true) {
                                  await apiService.deleteReceiverAddress(
                                    addressId: addr["id"],
                                  );
                                  if (context.mounted) {
                                    modalSetState(() {});
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildAddNewButton(
                    "Add New Receiver Address",
                    AddressColors.receiverPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      _resetReceiverForm();
                      _openAttractiveReceiverBottomSheet();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedInputField(
    String label,
    String hint, {
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AddressColors.surface,
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: 2),
            ),
            filled: true,
            fillColor: AddressColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSelectionCard(
    String title,
    double? selected,
    VoidCallback onTap,
    Color color, {
    String? locationName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected == null ? Icons.map_outlined : Icons.check,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        selected == null
                            ? "Tap to select on map"
                            : (locationName?.isNotEmpty == true
                                  ? locationName!
                                  : "Location selected ✓"),
                        style: TextStyle(
                          color: selected == null
                              ? AddressColors.textSecondary
                              : color,
                          fontSize: 14,
                          fontWeight: locationName?.isNotEmpty == true
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDropdowns(
    StateSetter setModalState, {
    required bool isSender,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAttractiveDropdown(
                hint: "Country",
                items: countries,
                loading: isCountryLoading,
                selectedId: isSender
                    ? selectedCountryId
                    : selectedReceiverCountryId,
                color: isSender
                    ? AddressColors.senderPrimary
                    : AddressColors.receiverPrimary,
                onChanged: (value) async {
                  if (isSender) {
                    selectedCountryId = value['id'];
                    senderCountryCtrl.text = value['name'];
                    selectedStateId = null;
                    selectedDistrictId = null;
                    states.clear();
                    districts.clear();
                    await _loadStates(selectedCountryId!);
                  } else {
                    selectedReceiverCountryId = value['id'];
                    receiverCountryCtrl.text = value['name'];
                    selectedReceiverStateId = null;
                    selectedReceiverDistrictId = null;
                    receiverStates.clear();
                    receiverDistricts.clear();
                    await _loadReceiverStates(selectedReceiverCountryId!);
                  }
                  setModalState(() {});
                },
              ),
            ),
            Expanded(
              child: _buildAttractiveDropdown(
                hint: "State",
                items: isSender ? states : receiverStates,
                loading: isSender ? isStateLoading : isReceiverStateLoading,
                selectedId: isSender
                    ? selectedStateId
                    : selectedReceiverStateId,
                color: isSender
                    ? AddressColors.senderPrimary
                    : AddressColors.receiverPrimary,
                onChanged: (value) async {
                  if (isSender) {
                    selectedStateId = value['id'];
                    senderStateCtrl.text = value['name'];
                    selectedDistrictId = null;
                    districts.clear();
                    await _loadDistricts(selectedStateId!);
                  } else {
                    selectedReceiverStateId = value['id'];
                    receiverStateCtrl.text = value['name'];
                    selectedReceiverDistrictId = null;
                    receiverDistricts.clear();
                    await _loadReceiverDistricts(selectedReceiverStateId!);
                  }
                  setModalState(() {});
                },
              ),
            ),
          ],
        ),
        _buildAttractiveDropdown(
          hint: "District",
          items: isSender ? districts : receiverDistricts,
          loading: isSender ? isDistrictLoading : isReceiverDistrictLoading,
          selectedId: isSender
              ? selectedDistrictId
              : selectedReceiverDistrictId,
          color: isSender
              ? AddressColors.senderPrimary
              : AddressColors.receiverPrimary,
          onChanged: (value) {
            if (isSender) {
              selectedDistrictId = value['id'];
              senderDistrictCtrl.text = value['name'];
            } else {
              selectedReceiverDistrictId = value['id'];
              receiverDistrictCtrl.text = value['name'];
            }
            setModalState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildAttractiveDropdown({
    required String hint,
    required List<dynamic> items,
    required bool loading,
    required int? selectedId,
    required Color color,
    required Function(dynamic) onChanged,
  }) {
    final hasValue =
        items.isNotEmpty &&
        selectedId != null &&
        items.any((e) => e['id'] == selectedId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AddressColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: DropdownButtonFormField<int>(
          value: hasValue ? selectedId : null,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: AddressColors.textSecondary),
          ),
          items: items
              .map<DropdownMenuItem<int>>(
                (item) => DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(
                    item['name'],
                    style: const TextStyle(color: AddressColors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: loading || items.isEmpty
              ? null
              : (id) {
                  final selectedItem = items.firstWhere((e) => e['id'] == id);
                  onChanged(selectedItem);
                },
          decoration: InputDecoration(
            filled: true,
            fillColor: AddressColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          icon: Icon(Icons.arrow_drop_down, color: color),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildAttractiveSaveButton({
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: ColorConstants.red,

          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Save Address",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttractiveAddressListItem({
    required Map<String, dynamic> addr,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addr["sender_name"] ?? addr["receiver_name"] ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${addr["address"] ?? addr["address_text"] ?? ""}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AddressColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${addr["district"]}, ${addr["state"]}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AddressColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                        onPressed: onDelete,
                        splashRadius: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: color,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: AddressColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewButton(
    String title,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(title, style: TextStyle(color: ColorConstants.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Address?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
