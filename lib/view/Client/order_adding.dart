import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/order_placing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  File? productImage;
  bool isInitializingDefaults = true;
  final picker = ImagePicker();
  bool isUserChangingCountry = false;
  bool isUserChangingState = false;
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

  Future<Position?> _getReceiverLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please turn ON location")));
      return null;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission permanently denied")),
      );
      return null;
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _loadReceiverStates(int countryId) async {
    isReceiverStateLoading = true;
    setState(() {});

    try {
      if (!stateCache.containsKey(0)) {
        stateCache[0] = await apiService.getStates(countryId: countryId);
      }

      final countryName = countries.firstWhere(
        (c) => c['id'] == countryId,
      )['name'];

      receiverStates = stateCache[0]!
          .where((s) => s['country'] == countryName)
          .toList();
    } catch (e) {
      debugPrint("Receiver State load error: $e");
    }

    isReceiverStateLoading = false;
    setState(() {});
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    isReceiverDistrictLoading = true;
    setState(() {});

    try {
      if (!districtCache.containsKey(0)) {
        districtCache[0] = await apiService.getDistricts(stateId: stateId);
      }

      receiverDistricts = districtCache[0]!
          .where((d) => d['state'] == stateId)
          .toList();
    } catch (e) {
      debugPrint("Receiver District load error: $e");
    }

    isReceiverDistrictLoading = false;
    setState(() {});
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
        stateCache[0] = await apiService.getStates(countryId: countryId);
      }
      final countryName = countries.firstWhere(
        (c) => c['id'] == countryId,
      )['name'];
      states = stateCache[0]!
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
        districtCache[0] = await apiService.getDistricts(stateId: stateId);
      }
      districts = districtCache[0]!
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
      backgroundColor: ColorConstants.bg,
      bottomNavigationBar: _buildBottomButton(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(context),
            SizedBox(height: 20),
            _input(
              "Product Name",
              "e.g. iPhone 15 Pro Max",
              controller: nameCtrl,
            ),
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
            SizedBox(height: 10),
            _sectionHeader("SENDER ADDRESS"),
            _input(
              "Sender Name",
              "Enter full name",
              controller: senderNameCtrl,
            ),
            _input(
              "Phone Number",
              "+1  (555) 000-0000",
              controller: senderPhoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            _input(
              "Full Address",
              "Street, Building, Apartment",
              controller: senderAddressCtrl,
            ),
            _input(
              "Landmark",
              "Near by central park...",
              controller: senderLandmarkCtrl,
            ),
            _input(
              "Zip Code",
              "Zip Code",
              controller: senderZipCtrl,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: apiDropdown(
                      hint: "Country",
                      items: countries,
                      loading: isCountryLoading,
                      selectedId: selectedCountryId,
                      onChanged: (value) async {
                        if (value == null) return;
                        final countryId = value['id'];
                        setState(() {
                          isUserChangingCountry = true;
                          selectedCountryId = countryId;
                          senderCountryCtrl.text = value['name'];
                          selectedStateId = null;
                          selectedDistrictId = null;
                          states = [];
                          districts = [];
                        });
                        await _loadStates(countryId);
                        isUserChangingCountry = false;
                      },
                    ),
                  ),
                  Expanded(
                    child: apiDropdown(
                      hint: "State",
                      items: states,
                      loading: isStateLoading,
                      selectedId: selectedStateId,
                      onChanged: (value) async {
                        if (value == null) return;
                        final stateId = value['id'];
                        setState(() {
                          isUserChangingState = true;
                          selectedStateId = stateId;
                          senderStateCtrl.text = value['name'];
                          selectedDistrictId = null;
                          districts = [];
                        });

                        await _loadDistricts(stateId);

                        isUserChangingState = false;
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: apiDropdown(
                hint: "District",
                items: selectedStateId == null ? [] : districts,
                loading: isDistrictLoading,
                selectedId: selectedDistrictId,
                onChanged: (value) {
                  setState(() {
                    selectedDistrictId = value["id"];
                    senderDistrictCtrl.text = value["name"];
                  });
                },
              ),
            ),
            _sectionHeader("RECEIVER ADDRESS"),
            _input(
              "Receiver Name",
              "Recipient's full name",
              controller: receiverNameCtrl,
            ),
            _input(
              "Phone Number",
              "+1  (555) 000-0000",
              controller: receiverPhoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            _input(
              "Full Address",
              "Delivery destination address",
              controller: receiverAddressCtrl,
            ),
            _input(
              "Landmark",
              "e.g. Opposite the library",
              controller: receiverLandmarkCtrl,
            ),
            _input(
              "Zip Code",
              "000000",
              controller: receiverZipCtrl,
              keyboardType: TextInputType.number,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: apiDropdown(
                      hint: "Country",
                      items: countries,
                      loading: isCountryLoading,
                      selectedId: selectedReceiverCountryId,
                      onChanged: (value) async {
                        if (value == null) return;
                        final countryId = value['id'];
                        setState(() {
                          selectedReceiverCountryId = countryId;
                          receiverCountryCtrl.text = value['name'];
                          selectedReceiverStateId = null;
                          selectedReceiverDistrictId = null;
                          receiverStates = [];
                          receiverDistricts = [];
                          receiverStateCtrl.clear();
                          receiverDistrictCtrl.clear();
                        });

                        await _loadReceiverStates(countryId);
                      },
                    ),
                  ),
                  Expanded(
                    child: apiDropdown(
                      hint: "State",
                      items: receiverStates,
                      loading: isReceiverStateLoading,
                      selectedId: selectedReceiverStateId,
                      onChanged: (value) async {
                        if (value == null) return;
                        final stateId = value['id'];
                        setState(() {
                          selectedReceiverStateId = stateId;
                          receiverStateCtrl.text = value['name'];
                          selectedReceiverDistrictId = null;
                          receiverDistricts = [];
                          receiverDistrictCtrl.clear();
                        });

                        await _loadReceiverDistricts(stateId);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: apiDropdown(
                hint: "District",
                items: selectedReceiverStateId == null ? [] : receiverDistricts,
                loading: isReceiverDistrictLoading,
                selectedId: selectedReceiverDistrictId,
                onChanged: (value) {
                  setState(() {
                    selectedReceiverDistrictId = value["id"];
                    receiverDistrictCtrl.text = value["name"];
                  });
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: Colors.red,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
          Text(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageUploadBox() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xffEFF1F7),
          ),
          child: productImage == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 30),
                      SizedBox(height: 8),
                      Text("Tap to upload product photo"),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    productImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
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
        onPressed: () async {
          if (nameCtrl.text.isEmpty ||
              volumeCtrl.text.isEmpty ||
              senderAddressCtrl.text.isEmpty ||
              senderDistrictCtrl.text.isEmpty ||
              senderStateCtrl.text.isEmpty ||
              senderCountryCtrl.text.isEmpty ||
              senderZipCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all required fields")),
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
          final addressId = await apiService.addSenderAddress(
            name: senderNameCtrl.text,
            address: senderAddressCtrl.text,
            phone: senderPhoneCtrl.text,
            landmark: senderLandmarkCtrl.text,
            district: selectedDistrictId,
            state: selectedStateId,
            country: selectedCountryId,
            zipCode: senderZipCtrl.text,
          );
          if (addressId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Address creation failed")),
            );
            return;
          }
          final position = await _getReceiverLocation();
          String? latitude;
          String? longitude;
          if (position != null) {
            latitude = position.latitude.toString();
            longitude = position.longitude.toString();
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

          final receiverSuccess = await apiService.addReceiverAddress(
            productId: apiService.lastCreatedProductId!,
            receiverId: apiService.currentUserId!,
            receiverName: receiverNameCtrl.text,
            receiverPhone: receiverPhoneCtrl.text,
            address: receiverAddressCtrl.text,
            landmark: receiverLandmarkCtrl.text,
            district: selectedReceiverDistrictId,
            state: selectedReceiverStateId,
            country: selectedReceiverCountryId,
            zipCode: receiverZipCtrl.text,
            latitude: latitude,
            longitude: longitude,
          );

          if (receiverSuccess == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Receiver address failed")),
            );
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderPlacedScreen(
                productId: apiService.lastCreatedProductId!,
                senderAddressId: addressId,
                receiverAddressId: receiverSuccess,
              ),
            ),
          );
        },
        child: const Text(
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
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Select Your Role",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
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
}
