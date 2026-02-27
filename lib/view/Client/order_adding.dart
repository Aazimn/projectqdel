import 'dart:io';
// import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/map_picker.dart';
import 'package:projectqdel/view/Client/order_placing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // ✅ CORRECT KEYS
    senderCountryCtrl.text = addr["country"] ?? "";
    senderStateCtrl.text = addr["state"] ?? "";
    senderDistrictCtrl.text = addr["district"] ?? "";

    // 🔥 restore IDs from names
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
      final List<dynamic> data = await apiService
          .getReceiverAddresses(); // GET API

      // latest first (recent on top)
      receiverAddressList = List<Map<String, dynamic>>.from(data.reversed);
    } catch (e) {
      debugPrint("Receiver list error: $e");
      receiverAddressList = [];
    }

    setState(() => isReceiverLoading = false);
  }

  Future<void> _applyReceiverAddress(Map<String, dynamic> addr) async {
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
    receiverStates = stateCache[countryId]!;
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    if (!districtCache.containsKey(stateId)) {
      districtCache[stateId] = await apiService.getDistricts(stateId: stateId);
    }
    receiverDistricts = districtCache[stateId]!;
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
        stateCache[countryId] = await apiService.getStates(countryId: countryId);
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
        districtCache[stateId] = await apiService.getDistricts(stateId: stateId);
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
            isSenderCompleted ? _savedSenderCard() : _addSenderCard(),
            _sectionHeader("RECEIVER ADDRESS"),
            isReceiverCompleted ? _savedReceiverCard() : _addReceiverCard(),
          ],
        ),
      ),
    );
  }

  Widget _addSenderCard() {
    return _addressCard(
      title: "Sender Address",
      subtitle: "Tap to add sender address",
      completed: false,
      onTap: _openSenderAddressSelectorSheet,
    );
  }

  Widget _savedSenderCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
        decoration: BoxDecoration(
          color: const Color(0xffE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Sender Address Saved",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              senderNameCtrl.text.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 5),
            Text(senderAddressCtrl.text),
            Text(senderLandmarkCtrl.text),
            Text(senderZipCtrl.text),
            Text(senderPhoneCtrl.text),
            Text(
              "${senderDistrictCtrl.text}, ${senderStateCtrl.text}, ${senderCountryCtrl.text}",
              style: TextStyle(color: Colors.grey.shade700),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openSenderAddressSelectorSheet,
                child: const Text("Edit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addReceiverCard() {
    return _addressCard(
      title: "Receiver Address",
      subtitle: "Tap to add receiver address",
      completed: false,
      onTap: _openReceiverAddressSelectorSheet,
    );
  }

  Widget _savedReceiverCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
        decoration: BoxDecoration(
          color: const Color(0xffE3F2FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Receiver Address Saved",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              receiverNameCtrl.text.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 5),
            Text(receiverAddressCtrl.text),
            Text(receiverLandmarkCtrl.text),
            Text(receiverZipCtrl.text),
            Text(receiverPhoneCtrl.text),
            Text(
              "${receiverDistrictCtrl.text}, ${receiverStateCtrl.text}, ${receiverCountryCtrl.text}",
              style: TextStyle(color: Colors.grey.shade700),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openReceiverAddressSelectorSheet,
                child: const Text("Edit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReceiverBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sheetHeader("Receiver Address"),

                    _input(
                      "Receiver Name",
                      "Full name",
                      controller: receiverNameCtrl,
                    ),
                    _input(
                      "Phone",
                      "Phone number",
                      controller: receiverPhoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    _input(
                      "Address",
                      "Full address",
                      controller: receiverAddressCtrl,
                    ),
                    _input(
                      "Landmark",
                      "Nearby landmark",
                      controller: receiverLandmarkCtrl,
                    ),
                    _input(
                      "Zip Code",
                      "Zip",
                      controller: receiverZipCtrl,
                      keyboardType: TextInputType.number,
                    ),

                    // MAP PICKER
                    TextButton.icon(
                      icon: const Icon(Icons.map),
                      label: Text(
                        receiverLat == null
                            ? "Select Delivery Location"
                            : "Location Selected",
                      ),
                      onPressed: () async {
                        final LatLng? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapPickerScreen(),
                          ),
                        );
                        if (result != null) {
                          setModalState(() {
                            receiverLat = result.latitude;
                            receiverLng = result.longitude;
                          });
                        }
                      },
                    ),

                    // COUNTRY / STATE
                    Row(
                      children: [
                        Expanded(
                          child: apiDropdown(
                            hint: "Country",
                            items: countries,
                            loading: isCountryLoading,
                            selectedId: selectedReceiverCountryId,
                            onChanged: (value) async {
                              selectedReceiverCountryId = value['id'];
                              receiverCountryCtrl.text = value['name'];

                              selectedReceiverStateId = null;
                              selectedReceiverDistrictId = null;
                              receiverStates.clear();
                              receiverDistricts.clear();

                              await _loadReceiverStates(
                                selectedReceiverCountryId!,
                              );
                              setModalState(() {});
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
                              selectedReceiverStateId = value['id'];
                              receiverStateCtrl.text = value['name'];

                              selectedReceiverDistrictId = null;
                              receiverDistricts.clear();

                              await _loadReceiverDistricts(
                                selectedReceiverStateId!,
                              );
                              setModalState(() {});
                            },
                          ),
                        ),
                      ],
                    ),

                    // DISTRICT
                    apiDropdown(
                      hint: "District",
                      items: receiverDistricts,
                      loading: isReceiverDistrictLoading,
                      selectedId: selectedReceiverDistrictId,
                      onChanged: (value) {
                        selectedReceiverDistrictId = value['id'];
                        receiverDistrictCtrl.text = value['name'];
                        setModalState(() {});
                      },
                    ),

                    const SizedBox(height: 12),

                    _saveSheetButton(
                      onTap: () async {
                        if (receiverNameCtrl.text.isEmpty ||
                            selectedReceiverDistrictId == null ||
                            receiverLat == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please complete receiver address"),
                            ),
                          );
                          return;
                        }
                        // ➕ CREATE NEW RECEIVER (your existing flow)
                        await apiService.addReceiverAddress(
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

                        isReceiverCompleted = true;

                        Navigator.pop(context);
                        await _loadReceiverAddresses();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(50),
              topRight: Radius.circular(5),
            ),
            color: Colors.red,
          ),
          width: 200,
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
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xffEFF1F7),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard({
    required String title,
    required String subtitle,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xffEFF1F7),
            border: Border.all(
              color: completed ? Colors.green : Colors.black,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.location_on_outlined,
                color: completed ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openSenderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sheetHeader("Sender Address"),

                    _input(
                      "Sender Name",
                      "Full name",
                      controller: senderNameCtrl,
                    ),
                    _input(
                      "Phone",
                      "Phone number",
                      controller: senderPhoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    _input(
                      "Address",
                      "Full address",
                      controller: senderAddressCtrl,
                    ),
                    _input(
                      "Landmark",
                      "Nearby landmark",
                      controller: senderLandmarkCtrl,
                    ),
                    _input(
                      "Zip Code",
                      "Zip",
                      controller: senderZipCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.map),
                      label: Text(
                        senderLat == null
                            ? "Select Pickup Location"
                            : "Location Selected",
                      ),
                      onPressed: () async {
                        final LatLng? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapPickerScreen(),
                          ),
                        );
                        if (result != null) {
                          setModalState(() {
                            senderLat = result.latitude;
                            senderLng = result.longitude;
                          });
                        }
                      },
                    ),
                    _senderDropdownSection(),

                    const SizedBox(height: 16),
                    _saveSheetButton(
                      onTap: () async {
                        if (senderNameCtrl.text.isEmpty ||
                            selectedDistrictId == null ||
                            senderLat == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please complete sender address"),
                            ),
                          );
                          return;
                        }

                        final success = await apiService.addSenderAddress(
                          name: senderNameCtrl.text,
                          phone: senderPhoneCtrl.text,
                          address: senderAddressCtrl.text,
                          landmark: senderLandmarkCtrl.text,
                          district: selectedDistrictId,
                          state: selectedStateId,
                          country: selectedCountryId,
                          zipCode: senderZipCtrl.text,
                          latitude: senderLat.toString(),
                          longitude: senderLng.toString(),
                        );

                        if (success == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to save sender address"),
                            ),
                          );
                          return;
                        }

                        isSenderCompleted = true;
                        Navigator.pop(context);
                        await _loadSenderAddresses();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      height: 60,
      width: double.infinity,

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: ColorConstants.white,
          ),
        ),
      ),
    );
  }

  Widget _saveSheetButton({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
        child: SizedBox(
          height: 20,
          width: 110,
          child: Center(
            child: Text(
              "Save Address",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSenderAddressSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool loading = true;
        List<Map<String, dynamic>> list = [];

        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> load() async {
              try {
                final data = await apiService.getSenderAddresses();
                if (!context.mounted) return;

                modalSetState(() {
                  list = List<Map<String, dynamic>>.from(data.reversed);
                  loading = false;
                });
              } catch (_) {
                if (!context.mounted) return;
                modalSetState(() => loading = false);
              }
            }

            if (loading && list.isEmpty) {
              load();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader("Select Sender Address"),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No saved sender addresses"),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final addr = list[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.red,
                                ),
                              ),
                              title: Text(
                                addr["sender_name"] ?? "",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(addr["address"] ?? ""),
                                  Text(
                                    "${addr["district"]}, ${addr["state"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text("Delete Address?"),
                                          content: Text(
                                            "This action cannot be undone",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await apiService.deleteSenderAddress(
                                          addressId: addr["id"],
                                        );

                                        modalSetState(() {
                                          list.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                _applySenderAddress(addr);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Add new sender address"),
                  onTap: () {
                    Navigator.pop(context);
                    _openSenderBottomSheet();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openReceiverAddressSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool loading = true;
        List<Map<String, dynamic>> list = [];

        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> load() async {
              try {
                final data = await apiService.getReceiverAddresses();
                if (!context.mounted) return;

                modalSetState(() {
                  list = List<Map<String, dynamic>>.from(data.reversed);
                  loading = false;
                });
              } catch (_) {
                if (!context.mounted) return;
                modalSetState(() => loading = false);
              }
            }

            if (loading && list.isEmpty) {
              load();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHeader("Select Receiver Address"),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No saved receiver addresses"),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, index) {
                        final addr = list[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(
                                addr["receiver_name"] ?? "",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(addr["address_text"] ?? ""),
                                  Text(
                                    "${addr["district_name"]}, ${addr["state_name"]}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text("Delete Address?"),
                                          content: Text(
                                            "This action cannot be undone",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await apiService.deleteReceiverAddress(
                                          addressId: addr["id"],
                                        );

                                        modalSetState(() {
                                          list.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                _applyReceiverAddress(addr);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Add new receiver address"),
                  onTap: () {
                    Navigator.pop(context);
                    _openReceiverBottomSheet();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _senderDropdownSection() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: apiDropdown(
                    hint: "Country",
                    items: countries,
                    loading: isCountryLoading,
                    selectedId: selectedCountryId,
                    onChanged: (value) async {
                      selectedCountryId = value['id'];
                      senderCountryCtrl.text = value['name'];
                      selectedStateId = null;
                      selectedDistrictId = null;
                      states.clear();
                      districts.clear();
                      await _loadStates(selectedCountryId!);
                      setModalState(() {});
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
                      selectedStateId = value['id'];
                      senderStateCtrl.text = value['name'];
                      selectedDistrictId = null;
                      districts.clear();
                      await _loadDistricts(selectedStateId!);
                      setModalState(() {});
                    },
                  ),
                ),
              ],
            ),
            apiDropdown(
              hint: "District",
              items: districts,
              loading: isDistrictLoading,
              selectedId: selectedDistrictId,
              onChanged: (value) {
                selectedDistrictId = value['id'];
                senderDistrictCtrl.text = value['name'];
                setModalState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _imageUploadBox() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Container(
          height: 100,
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.2),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xffEFF1F7),
          ),
          child: productImage == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 30,
                        color: ColorConstants.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tap to upload product",
                        style: TextStyle(color: ColorConstants.grey),
                      ),
                      Text(
                        "photo",
                        style: TextStyle(color: ColorConstants.grey),
                      ),
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
          if (!isSenderCompleted || !isReceiverCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please add sender & receiver address"),
              ),
            );
            return;
          }
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderPlacedScreen(
                productId: apiService.lastCreatedProductId!,
                senderAddressId: selectedSenderAddressId!,
                pickupId: selectedReceiverAddressId!,
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
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        const Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Add your Product",
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
