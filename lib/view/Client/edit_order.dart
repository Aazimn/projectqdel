import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/map_picker.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditOrder extends StatefulWidget {
  final int productId;
  final int senderAddressId;
  final int pickupId;
  const EditOrder({
    super.key,
    required this.productId,
    required this.senderAddressId,
    required this.pickupId,
  });

  @override
  State<EditOrder> createState() => _EditOrderState();
}

class _EditOrderState extends State<EditOrder> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? product;
  bool loading = true;
  bool showSuccessAnimation = true;
  int? id;
  Map<String, dynamic>? senderAddress;
  Map<String, dynamic>? receiverAddress;

  bool isUserChangingCountry = false;
  bool isUserChangingState = false;

  String? receiverLocationName;
  String? senderLocationName;

  double? senderLatitude;
  double? senderLongitude;

  double? receiverLatitude;
  double? receiverLongitude;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController volumeCtrl = TextEditingController();

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
  final TextEditingController receiverDistrictCtrl = TextEditingController();
  final TextEditingController receiverStateCtrl = TextEditingController();
  final TextEditingController receiverCountryCtrl = TextEditingController();
  final TextEditingController receiverZipCtrl = TextEditingController();

  List<dynamic> countries = [];
  List<dynamic> states = [];
  List<dynamic> districts = [];

  int? selectedCountryId;
  int? selectedStateId;
  int? selectedDistrictId;

  int? defaultCountryId;
  int? defaultStateId;
  int? defaultDistrictId;

  bool isCountryLoading = false;
  bool isStateLoading = false;
  bool isDistrictLoading = false;

  Map<int, List> stateCache = {};
  Map<int, List> districtCache = {};

  List<dynamic> receiverStates = [];
  List<dynamic> receiverDistricts = [];

  int? selectedReceiverCountryId;
  int? selectedReceiverStateId;
  int? selectedReceiverDistrictId;

  bool isReceiverStateLoading = false;
  bool isReceiverDistrictLoading = false;

  @override
  void initState() {
    super.initState();
    _initDefaults();
    _startFlow();
  }

  Future<void> _loadReceiverStates(int countryId) async {
    isReceiverStateLoading = true;
    setState(() {});
    try {
      if (!stateCache.containsKey(countryId)) {
        stateCache[countryId] = await apiService.getStates(
          countryId: countryId,
        );
      }
      final country = countries.firstWhere(
        (c) => c['id'] == countryId,
        orElse: () => null,
      );
      if (country == null) {
        debugPrint("Country not found for ID: $countryId");
        receiverStates = [];
      } else {
        final countryName = country['name'];
        debugPrint("Filtering states for country name: $countryName");
        receiverStates = stateCache[countryId]!
            .where((s) => s['country'] == countryName)
            .toList();
      }
      debugPrint(
        "Loaded ${receiverStates.length} states for country $countryId",
      );
      debugPrint(
        "States: ${receiverStates.map((s) => '${s['id']}: ${s['name']}').toList()}",
      );
    } catch (e) {
      debugPrint("Receiver State load error: $e");
    }
    isReceiverStateLoading = false;
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    isReceiverDistrictLoading = true;
    setState(() {});
    try {
      if (!districtCache.containsKey(stateId)) {
        districtCache[stateId] = await apiService.getDistricts(
          stateId: stateId,
        );
      }
      final state = receiverStates.firstWhere(
        (s) => s['id'] == stateId,
        orElse: () => null,
      );

      if (state == null) {
        receiverDistricts = [];
      } else {
        receiverDistricts = districtCache[stateId]!
            .where((d) => d['state'] == stateId)
            .toList();
      }
      debugPrint(
        "Loaded ${receiverDistricts.length} districts for state $stateId",
      );
      debugPrint(
        "Districts: ${receiverDistricts.map((d) => '${d['id']}: ${d['name']}').toList()}",
      );
    } catch (e) {
      debugPrint("Receiver District load error: $e");
    }
    isReceiverDistrictLoading = false;
  }

  bool isInitializingDefaults = true;

  int? savedCountryId;
  int? savedStateId;
  int? savedDistrictId;

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
    setState(() {
      isStateLoading = true;
      states = [];
      districts = [];
    });
    try {
      if (!stateCache.containsKey(countryId)) {
        stateCache[countryId] = await apiService.getStates(
          countryId: countryId,
        );
      }
      final country = countries.firstWhere(
        (c) => c['id'] == countryId,
        orElse: () => null,
      );
      if (country != null) {
        final countryName = country['name'];

        states = stateCache[countryId]!
            .where((s) => s['country'] == countryName)
            .toList();
      }
    } catch (e) {
      debugPrint("State load error: $e");
    }
    setState(() => isStateLoading = false);
  }

  Future<void> _loadDistricts(int stateId) async {
    setState(() {
      isDistrictLoading = true;
      districts = [];
    });

    try {
      if (!districtCache.containsKey(stateId)) {
        districtCache[stateId] = await apiService.getDistricts(
          stateId: stateId,
        );
      }
      districts = districtCache[stateId] ?? [];

      debugPrint("Loaded ${districts.length} districts for state $stateId");
      debugPrint(
        "Districts: ${districts.map((d) => '${d['id']}: ${d['name']}').toList()}",
      );
    } catch (e) {
      debugPrint("District load error: $e");
      districts = [];
    } finally {
      setState(() {
        isDistrictLoading = false;
      });
    }
  }

  void _fillControllers() {
    nameCtrl.text = product?['name'] ?? '';
    descCtrl.text = product?['description'] ?? '';
    weightCtrl.text = product?['actual_weight']?.toString() ?? '';
    volumeCtrl.text = product?['volume']?.toString() ?? '';
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() {
      showSuccessAnimation = false;
      loading = true;
    });

    await _loadProduct();
    await _loadSenderAddress();
    await _loadReceiverAddress();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> _loadSenderAddress() async {
    final response = await apiService.getSenderDetails(widget.pickupId);

    if (!mounted || response == null) return;

    final sender = response['sender_details'];
    final address = response['sender_address'];

    if (sender == null && address == null) return;

    final combined = <String, dynamic>{};

    if (sender != null) {
      combined['sender_name'] = address['sender_name'] ?? '';
      combined['phone_number'] = address['phone_number'] ?? '';
    }
    if (address != null) {
      combined['address'] = address['address'] ?? '';
      combined['landmark'] = address['landmark'] ?? '';
      combined['zip_code'] = address['zip_code'] ?? '';
      combined['district'] = address['district'] ?? '';
      combined['state'] = address['state'] ?? '';
      combined['country'] = address['country'] ?? '';

      combined['latitude'] = address['latitude'] ?? '';
      combined['longitude'] = address['longitude'] ?? '';

      senderLatitude = double.tryParse(address['latitude']?.toString() ?? '');
      senderLongitude = double.tryParse(address['longitude']?.toString() ?? '');

      if ((address['address'] == "200" ||
              address['address']?.isEmpty == true) &&
          senderLatitude != null &&
          senderLongitude != null) {
        try {
          String realLocationName = await _getLocationName(
            senderLatitude!,
            senderLongitude!,
          );
          setState(() {
            senderLocationName = realLocationName;
          });
        } catch (e) {
          debugPrint("Error getting location name: $e");
        }
      }
    }

    setState(() {
      senderAddress = combined;
    });

    senderNameCtrl.text = combined['sender_name'] ?? '';
    senderPhoneCtrl.text = combined['phone_number'] ?? '';
    senderAddressCtrl.text = combined['address'] ?? '';
    senderLandmarkCtrl.text = combined['landmark'] ?? '';
    senderZipCtrl.text = combined['zip_code'] ?? '';

    if (senderLocationName == null || senderLocationName?.isEmpty == true) {
      if (combined['address'] == "200" ||
          combined['address']?.isEmpty == true) {
        List<String> locationParts = [];
        if (combined['district'] != null &&
            combined['district'].toString().isNotEmpty) {
          locationParts.add(combined['district']);
        }
        if (combined['state'] != null &&
            combined['state'].toString().isNotEmpty) {
          locationParts.add(combined['state']);
        }
        if (combined['country'] != null &&
            combined['country'].toString().isNotEmpty) {
          locationParts.add(combined['country']);
        }

        senderLocationName = locationParts.isNotEmpty
            ? locationParts.join(", ")
            : "Selected location";
      } else {
        senderLocationName = combined['address'] ?? "Saved location";
      }
    }
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "Location at $lat, $lng";
  }

  Future<void> _loadReceiverAddress() async {
    final response = await apiService.getReceiverDetails(widget.pickupId);

    if (!mounted || response == null) return;
    final address = response['receiver_address'];

    if (address == null) {
      debugPrint("⚠️ Receiver not available yet");
      return;
    }

    Map<String, dynamic> combinedAddress = {};

    if (address != null) {
      combinedAddress['id'] = address['id'];
      combinedAddress['receiver_name'] = address['receiver_name'] ?? '';
      combinedAddress['receiver_phone'] = address['receiver_phone'] ?? '';
      combinedAddress['address_text'] = address['address_text'] ?? '';
      combinedAddress['landmark'] = address['landmark'] ?? '';
      combinedAddress['zip_code'] = address['zip_code'] ?? '';
      combinedAddress['district'] = address['district'] ?? '';
      combinedAddress['state'] = address['state'] ?? '';
      combinedAddress['country'] = address['country'] ?? '';
      combinedAddress['latitude'] = address['latitude'] ?? '';
      combinedAddress['longitude'] = address['longitude'] ?? '';

      receiverLatitude = double.tryParse(address['latitude']?.toString() ?? '');
      receiverLongitude = double.tryParse(
        address['longitude']?.toString() ?? '',
      );
    }

    setState(() {
      receiverAddress = combinedAddress;
    });

    receiverNameCtrl.text = combinedAddress['receiver_name'] ?? '';
    receiverPhoneCtrl.text = combinedAddress['receiver_phone'] ?? '';
    receiverAddressCtrl.text = combinedAddress['address_text'] ?? '';
    receiverLandmarkCtrl.text = combinedAddress['landmark'] ?? '';
    receiverZipCtrl.text = combinedAddress['zip_code'] ?? '';
    if (receiverLatitude != null && receiverLongitude != null) {
      try {
        String realLocationName = await _getLocationName(
          receiverLatitude!,
          receiverLongitude!,
        );
        setState(() {
          receiverLocationName = realLocationName;
          if (receiverAddress != null) {
            receiverAddress!['address_text'] = realLocationName;
          }
        });
      } catch (e) {
        debugPrint("Error getting receiver location name: $e");
        setState(() {
          receiverLocationName =
              combinedAddress['address_text'] ?? "Saved location";
        });
      }
    } else {
      receiverLocationName =
          combinedAddress['address_text'] ?? "Saved location";
    }

    debugPrint("✅ Loaded receiver address with ID: ${combinedAddress['id']}");
    debugPrint("📍 Receiver location name: $receiverLocationName");
  }

  Future<void> _loadProduct() async {
    try {
      final data = await apiService.getProductById(widget.productId);
      if (!mounted) return;
      if (data == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load product")));
      }
      setState(() {
        product = data;
      });
      _fillControllers();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _orderPlacedContent() {
    if (senderAddress == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    debugPrint("🟢 senderAddress: $senderAddress");
    debugPrint("🟢 receiverAddress: $receiverAddress");
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _searchingCard(),
                      const SizedBox(height: 16),
                      _orderSummary(),
                      const SizedBox(height: 16),

                      _detailsCard(
                        title: "SENDER DETAILS",
                        name: senderAddress?['sender_name'] ?? "—",
                        phone: senderAddress?['phone_number'] ?? "—",
                        address: senderAddress?['address'] ?? "—",
                        landmark: senderAddress?['landmark'],
                        district: senderAddress?['district'],
                        state: senderAddress?['state'],
                        country: senderAddress?['country'],
                        zip: senderAddress?['zip_code'],
                        onEdit: _openEditSenderSheet,
                      ),
                      const SizedBox(height: 16),
                      _detailsCard(
                        title: "RECEIVER DETAILS",
                        name: receiverAddress?['receiver_name'] ?? "—",
                        phone: receiverAddress?['receiver_phone'] ?? "—",
                        address: receiverAddress?['address_text'] ?? "—",
                        landmark: receiverAddress?['landmark'],
                        district: receiverAddress?['district'],
                        state: receiverAddress?['state'],
                        country: receiverAddress?['country'],
                        zip: receiverAddress?['zip_code'],
                        onEdit: _openEditReceiverSheet,
                      ),
                      const SizedBox(height: 16),
                      _cancelOrderSection(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _bottomButton(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: showSuccessAnimation
          ? const Center(child: CircularProgressIndicator())
          : _orderPlacedContent(),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.hourglass_top,
              color: Color(0xFFE53935),
              size: 30,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Waiting for Delivery Partner",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "We're confirming the nearest available rider",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _searchingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Text(
                      "Searching for Delivery Partner",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    _LiveDot(),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  "We're finding the nearest available rider for you",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order summery".toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _productImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product?['name'] ?? '').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      (product?['description'] ?? '').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "🔒 ${product?['actual_weight']} kg   📦 ${product?['volume']} cm³",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _openEditProductSheet();
            },
            icon: const Icon(Icons.edit, color: Colors.red),
            label: const Text(
              "Edit Order",
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Product",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _textField("Product Name", nameCtrl),
              _textField("Description", descCtrl),
              _textField("Weight (kg)", weightCtrl, isNumber: true),
              _textField("Volume (cm³)", volumeCtrl, isNumber: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Update Product"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    Navigator.pop(context);

    final success = await apiService.updateProduct(
      productId: widget.productId,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      actualWeight: weightCtrl.text.trim(),
      volume: volumeCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      await _loadProduct();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Product updated successfully"),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Failed to update product")),
        );
    }
  }

  Widget _detailsCard({
    required String title,
    required String name,
    required String phone,
    required String address,
    String? landmark,
    String? district,
    String? state,
    String? country,
    String? zip,
    VoidCallback? onEdit,
  }) {
  
    String displayAddress = address;
    if (title == "SENDER DETAILS" && senderLocationName != null) {
      displayAddress = senderLocationName!;
    } else if (title == "RECEIVER DETAILS" && receiverLocationName != null) {
      displayAddress = receiverLocationName!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: Icon(Icons.edit, color: Colors.red, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(phone),
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  displayAddress,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 117, 116, 116),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (landmark != null && landmark.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Landmark: $landmark",
              style: const TextStyle(
                color: Color.fromARGB(255, 117, 116, 116),
                fontSize: 12,
              ),
            ),
          ],
          if (zip != null && zip.isNotEmpty)
            Text(
              "Zip: $zip",
              style: const TextStyle(color: Color.fromARGB(255, 117, 116, 116)),
            ),
          if (district != null && district.isNotEmpty)
            Text(
              "District: $district",
              style: const TextStyle(color: Color.fromARGB(255, 117, 116, 116)),
            ),
          if (state != null && state.isNotEmpty)
            Text(
              "State: $state",
              style: const TextStyle(color: Color.fromARGB(255, 117, 116, 116)),
            ),
          if (country != null && country.isNotEmpty)
            Text(
              "Country: $country",
              style: const TextStyle(color: Color.fromARGB(255, 117, 116, 116)),
            ),
        ],
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

  Future<void> _openEditReceiverSheet() async {
    await _setReceiverDropdownDefaults();
    receiverLatitude = double.tryParse(
      receiverAddress?['latitude']?.toString() ?? '',
    );
    receiverLongitude = double.tryParse(
      receiverAddress?['longitude']?.toString() ?? '',
    );
    receiverLocationName = receiverAddress?['address_text'] ?? "Saved location";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Edit Receiver Address",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _textField("Receiver Name", receiverNameCtrl),
                    _textField("Phone", receiverPhoneCtrl, isNumber: true),
                    _textField("Address", receiverAddressCtrl),
                    _textField("Landmark", receiverLandmarkCtrl),
                    _textField("Zip Code", receiverZipCtrl, isNumber: true),
                    _buildMapSelectionCard(
                      "Receiver Location",
                      receiverLatitude,
                      () async {
                        debugPrint('🗺️ Opening map picker');

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapPickerScreen(),
                          ),
                        );

                        if (result != null) {
                          setModalState(() {
                            receiverLatitude = result['latitude'];
                            receiverLongitude = result['longitude'];
                            receiverLocationName = result['locationName'];
                          });

                          setState(() {
                            receiverLocationName = result['locationName'];
                            if (receiverAddress != null) {
                              receiverAddress!['address_text'] =
                                  result['locationName'];
                            }
                          });
                        }
                      },
                      Colors.red,
                      locationName: receiverLocationName,
                    ),
                    Row(
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
                              setModalState(() {
                                selectedReceiverCountryId = countryId;
                                receiverCountryCtrl.text = value['name'];
                                selectedReceiverStateId = null;
                                selectedReceiverDistrictId = null;
                                receiverStates.clear();
                                receiverDistricts.clear();
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
                              setModalState(() {
                                selectedReceiverStateId = stateId;
                                receiverStateCtrl.text = value['name'];
                                selectedReceiverDistrictId = null;
                                receiverDistricts = [];
                                receiverDistrictCtrl.clear();
                                isReceiverDistrictLoading = true;
                              });
                              await _loadReceiverDistricts(stateId);
                              setState(() {
                                isReceiverDistrictLoading = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    apiDropdown(
                      hint: "District",
                      items: selectedReceiverStateId == null
                          ? []
                          : receiverDistricts,
                      loading: isReceiverDistrictLoading,
                      selectedId: selectedReceiverDistrictId,
                      onChanged: (value) {
                        setModalState(() {
                          selectedReceiverDistrictId = value["id"];
                          receiverDistrictCtrl.text = value["name"];
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateReceiverAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Update Address"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateReceiverAddress() async {
    Navigator.pop(context);

    debugPrint("🟡 UPDATE RECEIVER STARTED");
    debugPrint("➡️ pickupId: ${widget.pickupId}");
    debugPrint("➡️ productId: ${widget.productId}");
    debugPrint("➡️ receiverId: ${apiService.currentUserId}");

    debugPrint("📦 ORIGINAL RECEIVER ADDRESS DATA:");
    debugPrint(receiverAddress.toString());

    debugPrint("➡️ receiverAddress ID: ${receiverAddress?['id']}");

    if (receiverAddress?['id'] == null) {
      debugPrint("❌ CRITICAL: receiverAddress ID is null!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error: Receiver address ID not found. Please refresh and try again.",
          ),
        ),
      );
      return;
    }

    final safeReceiverLat =
        receiverLatitude?.toString() ??
        (receiverAddress?['latitude'] != null
            ? receiverAddress!['latitude'].toString()
            : null);

    final safeReceiverLng =
        receiverLongitude?.toString() ??
        (receiverAddress?['longitude'] != null
            ? receiverAddress!['longitude'].toString()
            : null);

    final updatedReceiverName = receiverNameCtrl.text.trim().isEmpty
        ? (receiverAddress?['receiver_name'] ?? "").toString()
        : receiverNameCtrl.text.trim();

    final updatedPhone = receiverPhoneCtrl.text.trim().isEmpty
        ? (receiverAddress?['receiver_phone'] ?? "").toString()
        : receiverPhoneCtrl.text.trim();

    final updatedAddress = receiverAddressCtrl.text.trim().isEmpty
        ? (receiverAddress?['address_text'] ?? "").toString()
        : receiverAddressCtrl.text.trim();

    final updatedLandmark = receiverLandmarkCtrl.text.trim().isEmpty
        ? (receiverAddress?['landmark'] ?? "").toString()
        : receiverLandmarkCtrl.text.trim();

    final updatedZip = receiverZipCtrl.text.trim().isEmpty
        ? (receiverAddress?['zip_code'] ?? "").toString()
        : receiverZipCtrl.text.trim();

    debugPrint("📊 FINAL DATA BEING SENT TO API:");
    debugPrint("receiverName: $updatedReceiverName");
    debugPrint("phoneNumber: $updatedPhone");
    debugPrint("address: $updatedAddress");
    debugPrint("landmark: $updatedLandmark");
    debugPrint("latitude: $safeReceiverLat");
    debugPrint("longitude: $safeReceiverLng");
    debugPrint("districtId: $selectedReceiverDistrictId");
    debugPrint("stateId: $selectedReceiverStateId");
    debugPrint("countryId: $selectedReceiverCountryId");
    debugPrint("zipCode: $updatedZip");

    try {
      debugPrint("🚀 CALLING updateReceiverAddress API...");
      if (safeReceiverLat == null || safeReceiverLng == null) {
        debugPrint("❌ LATITUDE OR LONGITUDE MISSING");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select location on map before updating"),
          ),
        );
        return;
      }

      final success = await apiService.updateReceiverAddress(
        addressId: receiverAddress?['id'],
        productId: widget.productId,
        receiverId: apiService.currentUserId,

        receiverName: updatedReceiverName,
        phoneNumber: updatedPhone,
        address: updatedAddress,
        landmark: updatedLandmark,
        latitude: safeReceiverLat,
        longitude: safeReceiverLng,

        district: selectedReceiverDistrictId,
        state: selectedReceiverStateId,
        country: selectedReceiverCountryId,

        zipCode: updatedZip,
      );

      debugPrint("🟢 API RESULT: $success");

      if (!mounted) return;

      if (success) {
        debugPrint("✅ Receiver update SUCCESS → Reloading receiver address");
        if (receiverLocationName != null && receiverAddress != null) {
          receiverAddress!['address_text'] = receiverLocationName;
        }
        await _loadReceiverAddress();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receiver updated successfully")),
        );
      } else {
        debugPrint("❌ Receiver update FAILED");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update receiver address")),
        );
      }
    } catch (e, stack) {
      debugPrint("🔥 EXCEPTION DURING RECEIVER UPDATE");
      debugPrint("Error: $e");
      debugPrint("Stack: $stack");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating receiver: $e")));
    }
  }

  Future<void> _openEditSenderSheet() async {
    await _setSenderDropdownDefaults();

    senderLatitude = double.tryParse(
      senderAddress?['latitude']?.toString() ?? '',
    );
    senderLongitude = double.tryParse(
      senderAddress?['longitude']?.toString() ?? '',
    );

    if (senderLocationName == null || senderLocationName?.isEmpty == true) {
      senderLocationName = senderAddress?['address'] ?? "Saved location";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Edit Sender Address",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _textField("Sender Name", senderNameCtrl),
                    _textField("Phone Number", senderPhoneCtrl, isNumber: true),
                    _textField("Address", senderAddressCtrl),
                    _textField("Landmark", senderLandmarkCtrl),
                    _textField("Zip Code", senderZipCtrl, isNumber: true),

                    _buildMapSelectionCard(
                      "Sender Location",
                      senderLatitude,
                      () async {
                        debugPrint('🗺️ Opening map picker for sender');
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapPickerScreen(),
                          ),
                        );

                        if (result != null) {
                          setModalState(() {
                            senderLatitude = result['latitude'];
                            senderLongitude = result['longitude'];
                            senderLocationName =
                                result['locationName'];
                          });
                        }
                      },
                      Colors.red,
                      locationName: senderLocationName,
                    ),

                    Row(
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
                              setModalState(() {
                                selectedCountryId = countryId;
                                senderCountryCtrl.text = value['name'];
                                selectedStateId = null;
                                selectedDistrictId = null;
                                states = [];
                                districts = [];
                                senderStateCtrl.clear();
                                senderDistrictCtrl.clear();
                                isStateLoading = true;
                              });
                              await _loadStates(countryId);
                              setState(() {
                                isStateLoading = false;
                              });
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

                              setModalState(() {
                                selectedStateId = stateId;
                                senderStateCtrl.text = value['name'];
                                selectedDistrictId = null;
                                districts = [];
                                senderDistrictCtrl.clear();
                                isDistrictLoading = true;
                              });

                              await _loadDistricts(stateId);

                              setModalState(() {
                                isDistrictLoading = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    apiDropdown(
                      hint: "District",
                      items: selectedStateId == null ? [] : districts,
                      loading: isDistrictLoading,
                      selectedId: selectedDistrictId,
                      onChanged: (value) {
                        setModalState(() {
                          selectedDistrictId = value["id"];
                          senderDistrictCtrl.text = value["name"];
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateSenderAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Update Address"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateSenderAddress() async {
    Navigator.pop(context);

    debugPrint("🟡 UPDATE SENDER STARTED");
    debugPrint("➡️ senderAddressId: ${widget.senderAddressId}");
    final safeSenderLat =
        senderLatitude?.toString() ??
        (senderAddress?['latitude']?.toString() ?? '');
    final safeSenderLng =
        senderLongitude?.toString() ??
        (senderAddress?['longitude']?.toString() ?? '');

    debugPrint("📍 Sender Lat: $safeSenderLat, Lng: $safeSenderLng");

    if (safeSenderLat.isEmpty || safeSenderLng.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select location on map before updating"),
        ),
      );
      return;
    }

    final updatedSenderName = senderNameCtrl.text.trim().isEmpty
        ? (senderAddress?['sender_name'] ?? "").toString()
        : senderNameCtrl.text.trim();

    final updatedPhone = senderPhoneCtrl.text.trim().isEmpty
        ? (senderAddress?['phone_number'] ?? "").toString()
        : senderPhoneCtrl.text.trim();

    final updatedAddress = senderAddressCtrl.text.trim().isEmpty
        ? (senderAddress?['address'] ?? "").toString()
        : senderAddressCtrl.text.trim();

    final updatedLandmark = senderLandmarkCtrl.text.trim().isEmpty
        ? (senderAddress?['landmark'] ?? "").toString()
        : senderLandmarkCtrl.text.trim();

    final updatedZip = senderZipCtrl.text.trim().isEmpty
        ? (senderAddress?['zip_code'] ?? "").toString()
        : senderZipCtrl.text.trim();

    debugPrint("📦 DATA BEING SENT:");
    debugPrint("senderName: $updatedSenderName");
    debugPrint("phoneNumber: $updatedPhone");
    debugPrint("address: $updatedAddress");
    debugPrint("landmark: $updatedLandmark");
    debugPrint("zipCode: $updatedZip");
    debugPrint("districtId: $selectedDistrictId");
    debugPrint("stateId: $selectedStateId");
    debugPrint("countryId: $selectedCountryId");
    debugPrint("latitude: $safeSenderLat");
    debugPrint("longitude: $safeSenderLng");

    try {
      final success = await apiService.updateSenderAddress(
        addressId: widget.senderAddressId,
        senderName: updatedSenderName,
        phoneNumber: updatedPhone,
        address: updatedAddress,
        landmark: updatedLandmark,
        district: selectedDistrictId,
        state: selectedStateId,
        country: selectedCountryId,
        zipCode: updatedZip,
        latitude: safeSenderLat,
        longitude: safeSenderLng,
      );

      debugPrint("🟢 API RESULT: $success");

      if (!mounted) return;

      if (success) {
        debugPrint("✅ Sender update success → Reloading sender...");
        await _loadSenderAddress();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sender updated successfully")),
        );
      } else {
        debugPrint("❌ Sender update FAILED");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update sender address")),
        );
      }
    } catch (e) {
      debugPrint("🔥 EXCEPTION IN UPDATE SENDER:");
      debugPrint(e.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating sender: $e")));
    }
  }

  Widget _bottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const ClientDashboard(initialIndex: 2),
            ),
            (route) => false,
          );
        },
        icon: const Icon(Icons.list, color: ColorConstants.white),
        label: const Text(
          "Go to My Orders",
          style: TextStyle(color: ColorConstants.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 187, 27, 27),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ColorConstants.bgred),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _cancelOrderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: OutlinedButton.icon(
        onPressed: () {
          _showCancelDialog(context);
        },
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        label: const Text(
          "Cancel Order",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _productImage() {
    if (product == null) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }
    final images = product!['images'];
    if (images == null || images.isEmpty) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }
    final imagePath = images[0]['image'];
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }
    final imageUrl = "${apiService.baseurl}$imagePath";
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.grey);
        },
      ),
    );
  }

  Widget apiDropdown({
    required String hint,
    required List<dynamic> items,
    required bool loading,
    required int? selectedId,
    required Function(dynamic) onChanged,
  }) {
    final bool hasValidValue =
        selectedId != null && items.any((item) => item['id'] == selectedId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('${hint}_${selectedId}_${items.length}'),
        value: hasValidValue ? selectedId : null,
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

  Future<void> _setSenderDropdownDefaults() async {
    if (senderAddress == null) return;

    debugPrint("Setting sender defaults with address: $senderAddress");

    final countryName = senderAddress?['country'];
    final stateName = senderAddress?['state'];
    final districtName = senderAddress?['district'];

    debugPrint("Looking for country: $countryName");

    final country = countries.firstWhere(
      (c) => c['name'] == countryName,
      orElse: () => null,
    );

    if (country != null) {
      setState(() {
        selectedCountryId = country['id'];
        senderCountryCtrl.text = country['name'];
      });

      debugPrint("Found country: ${country['name']} with ID: ${country['id']}");
      await _loadStates(selectedCountryId!);

      debugPrint("Looking for state: $stateName in states: $states");
      final state = states.firstWhere(
        (s) => s['name'] == stateName,
        orElse: () => null,
      );

      if (state != null) {
        setState(() {
          selectedStateId = state['id'];
          senderStateCtrl.text = state['name'];
        });

        debugPrint("Found state: ${state['name']} with ID: ${state['id']}");
        await _loadDistricts(selectedStateId!);

        debugPrint(
          "Looking for district: $districtName in districts: $districts",
        );
        final district = districts.firstWhere(
          (d) => d['name'] == districtName,
          orElse: () => null,
        );

        if (district != null) {
          setState(() {
            selectedDistrictId = district['id'];
            senderDistrictCtrl.text = district['name'];
          });
          debugPrint(
            "Found district: ${district['name']} with ID: ${district['id']}",
          );
        } else {
          debugPrint("District not found: $districtName");
        }
      } else {
        debugPrint("State not found: $stateName");
      }
    } else {
      debugPrint("Country not found: $countryName");
    }

    setState(() {}); 
  }

  Future<void> _setReceiverDropdownDefaults() async {
    if (receiverAddress == null) return;

    final countryName = receiverAddress?['country'];
    final stateName = receiverAddress?['state'];
    final districtName = receiverAddress?['district'];

    final country = countries.firstWhere(
      (c) => c['name'] == countryName,
      orElse: () => null,
    );

    if (country != null) {
      selectedReceiverCountryId = country['id'];
      await _loadReceiverStates(selectedReceiverCountryId!);

      final state = receiverStates.firstWhere(
        (s) => s['name'] == stateName,
        orElse: () => null,
      );

      if (state != null) {
        selectedReceiverStateId = state['id'];
        await _loadReceiverDistricts(selectedReceiverStateId!);

        final district = receiverDistricts.firstWhere(
          (d) => d['name'] == districtName,
          orElse: () => null,
        );

        if (district != null) {
          selectedReceiverDistrictId = district['id'];
        }
      }
    }

    setState(() {});
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, color: Colors.red, size: 8),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
