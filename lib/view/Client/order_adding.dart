import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:logger/logger.dart';
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
class CountrySelector extends StatefulWidget {
  final int? selectedId;
  final Color color;
  final Function(Map<String, dynamic>) onSelected;

  const CountrySelector({
    super.key,
    this.selectedId,
    required this.color,
    required this.onSelected,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final ApiService apiService = ApiService();
  final Logger logger = Logger();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> countries = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasNext = false;
  String currentSearch = '';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => isLoading = true);
    try {
      final response = await apiService.getCountries(
        page: currentPage,
        search: currentSearch.isEmpty ? null : currentSearch,
      );

      if (response is List) {
        countries = response;
        hasNext = false;
      } else if (response is Map) {
        countries =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      }
    } catch (e) {
      logger.e("Country load error: $e");
      countries = [];
      hasNext = false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    currentSearch = query;
    currentPage = 1;
    await _loadCountries();
  }

  Future<void> _nextPage() async {
    if (!hasNext) return;
    currentPage++;
    await _loadCountries();
  }

  Future<void> _prevPage() async {
    if (currentPage <= 1) return;
    currentPage--;
    await _loadCountries();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildHeader("Select Country", widget.color),
          _buildSearchField(searchController, (query) => _search(query)),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: widget.color))
                : countries.isEmpty
                ? _buildEmptyState("No countries found", widget.color)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: countries.length,
                    itemBuilder: (context, index) {
                      final country = countries[index];
                      final isSelected = widget.selectedId == country['id'];
                      return _buildListItem(
                        country,
                        isSelected,
                        widget.color,
                        () {
                          widget.onSelected(country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          _buildPaginationHeader(),
        ],
      ),
    );
  }

  Widget _buildPaginationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: currentPage > 1 ? _prevPage : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: currentPage > 1 ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page $currentPage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: hasNext ? _nextPage : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: hasNext ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StateSelector extends StatefulWidget {
  final int? selectedId;
  final int countryId;
  final Color color;
  final Function(Map<String, dynamic>) onSelected;

  const StateSelector({
    super.key,
    this.selectedId,
    required this.countryId,
    required this.color,
    required this.onSelected,
  });

  @override
  State<StateSelector> createState() => _StateSelectorState();
}

class _StateSelectorState extends State<StateSelector> {
  final ApiService apiService = ApiService();
  final Logger logger = Logger();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> states = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasNext = false;
  String currentSearch = '';

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() => isLoading = true);
    try {
      final response = await apiService.getStatesByCountry(
        countryId: widget.countryId,
        page: currentPage,
        search: currentSearch.isEmpty ? null : currentSearch,
      );

      if (response is List) {
        states = response;
        hasNext = false;
      } else if (response is Map) {
        states =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      }
    } catch (e) {
      logger.e("State load error: $e");
      states = [];
      hasNext = false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    currentSearch = query;
    currentPage = 1;
    await _loadStates();
  }

  Future<void> _nextPage() async {
    if (!hasNext) return;
    currentPage++;
    await _loadStates();
  }

  Future<void> _prevPage() async {
    if (currentPage <= 1) return;
    currentPage--;
    await _loadStates();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildHeader("Select State", widget.color),
          _buildSearchField(searchController, (query) => _search(query)),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: widget.color))
                : states.isEmpty
                ? _buildEmptyState("No states found", widget.color)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: states.length,
                    itemBuilder: (context, index) {
                      final state = states[index];
                      final isSelected = widget.selectedId == state['id'];
                      return _buildListItem(
                        state,
                        isSelected,
                        widget.color,
                        () {
                          widget.onSelected(state);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          _buildPaginationHeader(),
        ],
      ),
    );
  }

  Widget _buildPaginationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: currentPage > 1 ? _prevPage : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: currentPage > 1 ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page $currentPage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: hasNext ? _nextPage : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: hasNext ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DistrictSelector extends StatefulWidget {
  final int? selectedId;
  final int stateId;
  final Color color;
  final Function(Map<String, dynamic>) onSelected;

  const DistrictSelector({
    super.key,
    this.selectedId,
    required this.stateId,
    required this.color,
    required this.onSelected,
  });

  @override
  State<DistrictSelector> createState() => _DistrictSelectorState();
}

class _DistrictSelectorState extends State<DistrictSelector> {
  final ApiService apiService = ApiService();
  final Logger logger = Logger();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> districts = [];
  bool isLoading = false;
  int currentPage = 1;
  bool hasNext = false;
  String currentSearch = '';

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    setState(() => isLoading = true);
    try {
      final response = await apiService.getDistrictsByState(
        stateId: widget.stateId,
        page: currentPage,
        search: currentSearch.isEmpty ? null : currentSearch,
      );

      if (response is List) {
        districts = response;
        hasNext = false;
      } else if (response is Map) {
        districts =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      }
    } catch (e) {
      logger.e("District load error: $e");
      districts = [];
      hasNext = false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    currentSearch = query;
    currentPage = 1;
    await _loadDistricts();
  }

  Future<void> _nextPage() async {
    if (!hasNext) return;
    currentPage++;
    await _loadDistricts();
  }

  Future<void> _prevPage() async {
    if (currentPage <= 1) return;
    currentPage--;
    await _loadDistricts();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildHeader("Select District", widget.color),
          _buildSearchField(searchController, (query) => _search(query)),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: widget.color))
                : districts.isEmpty
                ? _buildEmptyState("No districts found", widget.color)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: districts.length,
                    itemBuilder: (context, index) {
                      final district = districts[index];
                      final isSelected = widget.selectedId == district['id'];
                      return _buildListItem(
                        district,
                        isSelected,
                        widget.color,
                        () {
                          widget.onSelected(district);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          _buildPaginationHeader(),
        ],
      ),
    );
  }

  Widget _buildPaginationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: currentPage > 1 ? _prevPage : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: currentPage > 1 ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page $currentPage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: hasNext ? _nextPage : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: hasNext ? widget.color : Colors.grey,
                  ),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildHeader(String title, Color color) {
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
      ],
    ),
  );
}

Widget _buildSearchField(
  TextEditingController controller,
  Function(String) onChanged,
) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: controller,
      style: TextStyle(
        color: ColorConstants.white,
        fontWeight: FontWeight.bold,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search...",
        hintStyle: TextStyle(color: ColorConstants.white),
        prefixIcon: const Icon(Icons.search, color: ColorConstants.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: ColorConstants.red,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    ),
  );
}

Widget _buildListItem(
  dynamic item,
  bool isSelected,
  Color color,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      elevation: isSelected ? 2 : 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? color : AddressColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildEmptyState(String message, Color color) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_off, size: 80, color: color.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(fontSize: 18, color: AddressColors.textSecondary),
        ),
      ],
    ),
  );
}

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({super.key});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  final Logger logger = Logger();
  bool isSenderCompleted = false;
  bool isReceiverCompleted = false;
  List<Map<String, dynamic>> receiverAddressList = [];
  bool isReceiverLoading = false;
  List<Map<String, dynamic>> senderAddressList = [];
  bool isSenderLoading = false;
  int? selectedSenderAddressId;
  int? selectedReceiverAddressId;
  bool isCreatingShipment = false;

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
    logger.i("🔵 Applying sender address: ${addr['id']}");
    logger.i("Address data: $addr");

    selectedSenderAddressId = addr["id"];

    senderNameCtrl.text = addr["sender_name"] ?? "";
    senderPhoneCtrl.text = addr["phone_number"] ?? "";
    senderAddressCtrl.text = addr["address"] ?? "";
    senderLandmarkCtrl.text = addr["landmark"] ?? "";
    senderZipCtrl.text = addr["zip_code"] ?? "";

    senderLat = double.tryParse(addr["latitude"] ?? "");
    senderLng = double.tryParse(addr["longitude"] ?? "");
    logger.i("📍 Coordinates: lat=$senderLat, lng=$senderLng");

    senderCountryCtrl.text = addr["country"] ?? "";
    senderStateCtrl.text = addr["state"] ?? "";
    senderDistrictCtrl.text = addr["district"] ?? "";

    logger.i(
      "📍 Address text - Country: ${addr["country"]}, State: ${addr["state"]}, District: ${addr["district"]}",
    );
    logger.i(
      "🔍 Looking for country: ${addr["country"]} in countries list (${countries.length} items)",
    );
    final countryMatch = countries.firstWhere(
      (c) => c['name'] == addr["country"],
      orElse: () {
        logger.w("⚠️ Country not found: ${addr["country"]}");
        return null;
      },
    );

    selectedCountryId = countryMatch?['id'];
    logger.i("✅ Selected country ID: $selectedCountryId");

    if (selectedCountryId != null) {
      logger.i("📥 Loading states for country ID: $selectedCountryId");
      await _loadStates(selectedCountryId!);
      logger.i("📊 States loaded: ${states.length}");

      logger.i("🔍 Looking for state: ${addr["state"]} in states list");
      final stateMatch = states.firstWhere(
        (s) => s['name'] == addr["state"],
        orElse: () {
          logger.w("⚠️ State not found: ${addr["state"]}");
          return null;
        },
      );

      selectedStateId = stateMatch?['id'];
      logger.i("✅ Selected state ID: $selectedStateId");

      if (selectedStateId != null) {
        logger.i("📥 Loading districts for state ID: $selectedStateId");
        await _loadDistricts(selectedStateId!);
        logger.i("📊 Districts loaded: ${districts.length}");

        logger.i(
          "🔍 Looking for district: ${addr["district"]} in districts list",
        );
        final districtMatch = districts.firstWhere(
          (d) => d['name'] == addr["district"],
          orElse: () {
            logger.w("⚠️ District not found: ${addr["district"]}");
            return null;
          },
        );

        selectedDistrictId = districtMatch?['id'];
        logger.i("✅ Selected district ID: $selectedDistrictId");
      }
    } else {
      logger.e("❌ Failed to find country ID for: ${addr["country"]}");
    }

    logger.i(
      "✅ Final selection - Country: $selectedCountryId, State: $selectedStateId, District: $selectedDistrictId",
    );

    setState(() {
      isSenderCompleted = true;
    });
  }

  Future<void> _loadAllCountries() async {
    setState(() => isCountryLoading = true);

    List<dynamic> allCountries = [];
    int currentPage = 1;
    bool hasNextPage = true;

    try {
      logger.i("🔄 Starting to fetch ALL countries with pagination...");

      while (hasNextPage) {
        logger.i("📡 Fetching countries page $currentPage");

        final response = await apiService.getCountries(page: currentPage);

        if (response is List) {
          allCountries = response;
          logger.i("✅ Received ${response.length} countries (no pagination)");
          break;
        } else if (response is Map) {
          final pageCountries = (response['results'] as List?) ?? [];
          final hasNext = response['next'] != null;
          final totalCount = response['count'] ?? 0;
          allCountries.addAll(pageCountries);

          logger.i(
            "✅ Page $currentPage loaded: ${pageCountries.length} countries",
          );
          logger.i("   Total so far: ${allCountries.length}/$totalCount");
          logger.i("   Next page exists: $hasNext");

          hasNextPage = hasNext;
          currentPage++;

          if (currentPage > 50) {
            logger.w("⚠️ Reached page 50, stopping to prevent infinite loop");
            break;
          }
        } else {
          logger.e("❌ Unexpected response type: ${response.runtimeType}");
          break;
        }
      }

      setState(() {
        countries = allCountries;
        _countryPage = 1; 
        _countryHasNext = false; 
        logger.i("✅ FINAL: Loaded total ${countries.length} countries");
        logger.i(
          "🌍 All countries: ${countries.map((c) => c['name']).toList()}",
        );
      });
    } catch (e) {
      logger.e("❌ Error loading all countries: $e");
      setState(() {
        countries = [];
      });
    } finally {
      setState(() => isCountryLoading = false);
    }
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
    logger.i("🔵 Applying receiver address: ${addr['id']}");
    logger.i("Address data: $addr");

    selectedReceiverAddressId = addr["id"];

    receiverNameCtrl.text = addr["receiver_name"] ?? "";
    receiverPhoneCtrl.text = addr["receiver_phone"] ?? "";
    receiverAddressCtrl.text = addr["address_text"] ?? "";
    receiverLandmarkCtrl.text = addr["landmark"] ?? "";
    receiverZipCtrl.text = addr["zip_code"] ?? "";

    receiverLat = double.tryParse(addr["latitude"] ?? "");
    receiverLng = double.tryParse(addr["longitude"] ?? "");
    logger.i("📍 Coordinates: lat=$receiverLat, lng=$receiverLng");

    receiverCountryCtrl.text = addr["country"] ?? "";
    receiverStateCtrl.text = addr["state"] ?? "";
    receiverDistrictCtrl.text = addr["district"] ?? "";

    logger.i(
      "📍 Address text - Country: ${addr["country"]}, State: ${addr["state"]}, District: ${addr["district"]}",
    );

    logger.i(
      "🔍 Looking for country: ${addr["country"]} in countries list (${countries.length} items)",
    );
    final countryMatch = countries.firstWhere(
      (c) => c['name'] == addr["country"],
      orElse: () {
        logger.w("⚠️ Country not found: ${addr["country"]}");
        return null;
      },
    );

    selectedReceiverCountryId = countryMatch?['id'];
    logger.i("✅ Selected receiver country ID: $selectedReceiverCountryId");

    if (selectedReceiverCountryId == null) {
      logger.e("❌ Failed to find country ID for receiver: ${addr["country"]}");
      return;
    }

    logger.i(
      "📥 Loading receiver states for country ID: $selectedReceiverCountryId",
    );
    await _loadReceiverStates(selectedReceiverCountryId!);
    logger.i("📊 Receiver states loaded: ${receiverStates.length}");

    logger.i("🔍 Looking for state: ${addr["state"]} in receiver states list");
    final stateMatch = receiverStates.firstWhere(
      (s) => s['name'] == addr["state"],
      orElse: () {
        logger.w("⚠️ Receiver state not found: ${addr["state"]}");
        return null;
      },
    );

    selectedReceiverStateId = stateMatch?['id'];
    logger.i("✅ Selected receiver state ID: $selectedReceiverStateId");

    if (selectedReceiverStateId == null) {
      logger.e("❌ Failed to find state ID for receiver: ${addr["state"]}");
      return;
    }

    logger.i(
      "📥 Loading receiver districts for state ID: $selectedReceiverStateId",
    );
    await _loadReceiverDistricts(selectedReceiverStateId!);
    logger.i("📊 Receiver districts loaded: ${receiverDistricts.length}");

    logger.i(
      "🔍 Looking for district: ${addr["district"]} in receiver districts list",
    );
    final districtMatch = receiverDistricts.firstWhere(
      (d) => d['name'] == addr["district"],
      orElse: () {
        logger.w("⚠️ Receiver district not found: ${addr["district"]}");
        return null;
      },
    );

    selectedReceiverDistrictId = districtMatch?['id'];
    logger.i("✅ Selected receiver district ID: $selectedReceiverDistrictId");

    logger.i(
      "✅ Final receiver selection - Country: $selectedReceiverCountryId, State: $selectedReceiverStateId, District: $selectedReceiverDistrictId",
    );

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

  final TextEditingController countrySearchCtrl = TextEditingController();
  final TextEditingController senderStateSearchCtrl = TextEditingController();
  final TextEditingController receiverStateSearchCtrl = TextEditingController();
  final TextEditingController senderDistrictSearchCtrl =
      TextEditingController();
  final TextEditingController receiverDistrictSearchCtrl =
      TextEditingController();

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

  int _countryPage = 1;
  bool _countryHasNext = false;
  String _countrySearchQuery = '';

  int _senderStatePage = 1;
  bool _senderStateHasNext = false;
  String _senderStateSearchQuery = '';

  int _receiverStatePage = 1;
  bool _receiverStateHasNext = false;
  String _receiverStateSearchQuery = '';

  int _senderDistrictPage = 1;
  bool _senderDistrictHasNext = false;
  String _senderDistrictSearchQuery = '';

  int _receiverDistrictPage = 1;
  bool _receiverDistrictHasNext = false;
  String _receiverDistrictSearchQuery = '';

  final ApiService apiService = ApiService();

  Map<int, List> stateCache = {};
  Map<int, List> districtCache = {};

  int? savedCountryId;
  int? savedStateId;
  int? savedDistrictId;

  Future<void> _loadReceiverStates(int countryId) async {
    await _fetchReceiverStates(countryId: countryId, page: 1, search: null);
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    await _fetchReceiverDistricts(stateId: stateId, page: 1, search: null);
  }

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    isInitializingDefaults = true;

    await ApiService.loadSession();

    final prefs = await SharedPreferences.getInstance();
    apiService.currentUserId = prefs.getInt('user_id');
    savedCountryId = prefs.getInt('country');
    savedStateId = prefs.getInt('state');
    savedDistrictId = prefs.getInt('district');

    debugPrint(
      "Saved IDs => country:$savedCountryId state:$savedStateId district:$savedDistrictId",
    );
    await _loadAllCountries();
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
    await _fetchCountries(page: 1);
  }

  Future<void> _fetchCountries({int page = 1, String? search}) async {
    setState(() => isCountryLoading = true);
    try {
      logger.i("📡 Fetching countries page=$page search=$search");
      final response = await apiService.getCountries(
        page: page,
        search: search,
      );

      List<dynamic> data;
      bool hasNext = false;

      if (response is List) {
        data = response;
        hasNext = false;
      } else if (response is Map) {
        data =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      } else {
        throw Exception('Unexpected countries response type');
      }

      logger.i("✅ Countries loaded: ${data.length}, hasNext=$hasNext");
      if (data.isNotEmpty) {
        logger.i("Sample country: ${data.first}");
      }

      setState(() {
        countries = data;
        _countryPage = page;
        _countrySearchQuery = search ?? '';
        _countryHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ Country load error: $e");
      setState(() {
        countries = [];
        _countryHasNext = false;
      });
    } finally {
      setState(() => isCountryLoading = false);
    }
  }

  Future<void> _loadStates(int countryId) async {
    await _fetchSenderStates(countryId: countryId, page: 1, search: null);
  }

  Future<void> _loadDistricts(int stateId) async {
    await _fetchSenderDistricts(stateId: stateId, page: 1, search: null);
  }

  Future<void> _fetchSenderStates({
    required int countryId,
    required int page,
    String? search,
  }) async {
    setState(() => isStateLoading = true);
    try {
      logger.i(
        "📡 Fetching sender states countryId=$countryId page=$page search=$search",
      );
      final response = await apiService.getStatesByCountry(
        countryId: countryId,
        page: page,
        search: search,
      );

      List<dynamic> data;
      bool hasNext = false;

      if (response is List) {
        data = response;
        hasNext = false;
      } else if (response is Map) {
        data =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      } else {
        throw Exception('Unexpected states response type');
      }

      logger.i("✅ Sender states loaded: ${data.length}, hasNext=$hasNext");
      if (data.isNotEmpty) {
        logger.i("Sample state: ${data.first}");
      }

      setState(() {
        states = data;
        _senderStatePage = page;
        _senderStateSearchQuery = search ?? '';
        _senderStateHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ Sender state load error: $e");
      setState(() {
        states = [];
        _senderStateHasNext = false;
      });
    } finally {
      setState(() => isStateLoading = false);
    }
  }

  Future<void> _fetchReceiverStates({
    required int countryId,
    required int page,
    String? search,
  }) async {
    setState(() => isReceiverStateLoading = true);
    try {
      logger.i(
        "Loading receiver states countryId=$countryId page=$page search=$search",
      );
      final response = await apiService.getStatesByCountry(
        countryId: countryId,
        page: page,
        search: search,
      );

      List<dynamic> data;
      bool hasNext = false;

      if (response is List) {
        data = response;
        hasNext = false;
      } else if (response is Map) {
        data =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      } else {
        throw Exception('Unexpected states response type');
      }

      setState(() {
        receiverStates = data;
        _receiverStatePage = page;
        _receiverStateSearchQuery = search ?? '';
        _receiverStateHasNext = hasNext;
      });
      logger.i(
        "Receiver states page=$_receiverStatePage loaded: ${receiverStates.length}, hasNext=$_receiverStateHasNext",
      );
    } catch (e) {
      logger.e("Receiver state load error: $e");
      setState(() {
        receiverStates = [];
        _receiverStateHasNext = false;
      });
    } finally {
      setState(() => isReceiverStateLoading = false);
    }
  }

  Future<void> _fetchSenderDistricts({
    required int stateId,
    required int page,
    String? search,
  }) async {
    setState(() => isDistrictLoading = true);
    try {
      logger.i(
        "📡 Fetching sender districts stateId=$stateId page=$page search=$search",
      );
      final response = await apiService.getDistrictsByState(
        stateId: stateId,
        page: page,
        search: search,
      );

      List<dynamic> data;
      bool hasNext = false;

      if (response is List) {
        data = response;
        hasNext = false;
      } else if (response is Map) {
        data =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      } else {
        throw Exception('Unexpected districts response type');
      }

      logger.i("✅ Sender districts loaded: ${data.length}, hasNext=$hasNext");
      if (data.isNotEmpty) {
        logger.i("Sample district: ${data.first}");
      }

      setState(() {
        districts = data;
        _senderDistrictPage = page;
        _senderDistrictSearchQuery = search ?? '';
        _senderDistrictHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ Sender district load error: $e");
      setState(() {
        districts = [];
        _senderDistrictHasNext = false;
      });
    } finally {
      setState(() => isDistrictLoading = false);
    }
  }

  Future<void> _fetchReceiverDistricts({
    required int stateId,
    required int page,
    String? search,
  }) async {
    setState(() => isReceiverDistrictLoading = true);
    try {
      logger.i(
        "Loading receiver districts stateId=$stateId page=$page search=$search",
      );
      final response = await apiService.getDistrictsByState(
        stateId: stateId,
        page: page,
        search: search,
      );

      List<dynamic> data;
      bool hasNext = false;

      if (response is List) {
        data = response;
        hasNext = false;
      } else if (response is Map) {
        data =
            (response['results'] as List?) ??
            (response['data'] as List?) ??
            <dynamic>[];
        hasNext = response['next'] != null;
      } else {
        throw Exception('Unexpected districts response type');
      }

      setState(() {
        receiverDistricts = data;
        _receiverDistrictPage = page;
        _receiverDistrictSearchQuery = search ?? '';
        _receiverDistrictHasNext = hasNext;
      });
      logger.i(
        "Receiver districts page=$_receiverDistrictPage loaded: ${receiverDistricts.length}, hasNext=$_receiverDistrictHasNext",
      );
    } catch (e) {
      logger.e("Receiver district load error: $e");
      setState(() {
        receiverDistricts = [];
        _receiverDistrictHasNext = false;
      });
    } finally {
      setState(() => isReceiverDistrictLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() {
        productImage = File(picked.path);
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadAllCountries();
    if (selectedStateId != null) {
      await _fetchSenderDistricts(
        stateId: selectedStateId!,
        page: _senderDistrictPage,
        search: _senderDistrictSearchQuery,
      );
    }
    if (selectedCountryId != null) {
      await _fetchSenderStates(
        countryId: selectedCountryId!,
        page: _senderStatePage,
        search: _senderStateSearchQuery,
      );
    }
    if (selectedReceiverCountryId != null) {
      await _fetchReceiverStates(
        countryId: selectedReceiverCountryId!,
        page: _receiverStatePage,
        search: _receiverStateSearchQuery,
      );
    }
    if (selectedReceiverStateId != null) {
      await _fetchReceiverDistricts(
        stateId: selectedReceiverStateId!,
        page: _receiverDistrictPage,
        search: _receiverDistrictSearchQuery,
      );
    }
    await _loadSenderAddresses();
    await _loadReceiverAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 30),
              _buildProductFieldsSection(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "SENDER ADDRESS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              isSenderCompleted
                  ? _buildSavedAddressCard(
                      type: "Sender",
                      primaryColor: ColorConstants.red,
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
                      primaryColor: ColorConstants.black,
                      lightColor: AddressColors.senderLight,
                      onTap: _openAttractiveSenderSelectorSheet,
                    ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "RECEIVER ADDRESS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              isReceiverCompleted
                  ? _buildSavedAddressCard(
                      type: "Receiver",
                      primaryColor: ColorConstants.red,
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
                      locationName: receiverLocationName,
                      lat: receiverLat,
                      lng: receiverLng,
                    )
                  : _buildAttractiveAddressCard(
                      title: "Receiver Address",
                      subtitle: "Add delivery location details",
                      iconPath: "assets/receiver_icon.png",
                      primaryColor: ColorConstants.black,
                      lightColor: AddressColors.receiverLight,
                      onTap: _openAttractiveReceiverSelectorSheet,
                    ),
              _buildBottomButton(),
            ],
          ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                    color: Colors.black.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ColorConstants.red,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstants.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ColorConstants.red, width: 2),
                ),
                prefixIcon: _getPrefixIconForField(label),
                prefixIconColor: ColorConstants.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

    if (savedCountryId != null && countries.isNotEmpty) {
      try {
        final country = countries.firstWhere(
          (c) => c['id'] == savedCountryId,
          orElse: () => {},
        );
        if (country is Map && country.isNotEmpty) {
          senderCountryCtrl.text = country['name'] ?? '';
        } else {
          senderCountryCtrl.clear();
        }
      } catch (e) {
        logger.e("Reset sender form country lookup failed: $e");
        senderCountryCtrl.clear();
      }
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
              color: Colors.black,
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
                  color: Colors.black.withOpacity(0.3),
                  width: 1.5,
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: ColorConstants.red,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isCreatingShipment
                ? null
                : () async {
                    logger.i("🚀 ===== CREATE SHIPMENT ATTEMPT =====");
                    logger.i("Product Name: ${nameCtrl.text}");
                    logger.i("Volume: ${volumeCtrl.text}");
                    logger.i("Weight: ${weightCtrl.text}");
                    logger.i("Product Image: ${productImage?.path}");

                    logger.i("📦 SENDER DETAILS:");
                    logger.i("  Name: ${senderNameCtrl.text}");
                    logger.i("  Phone: ${senderPhoneCtrl.text}");
                    logger.i("  Address: ${senderAddressCtrl.text}");
                    logger.i("  Landmark: ${senderLandmarkCtrl.text}");
                    logger.i("  Zip: ${senderZipCtrl.text}");
                    logger.i(
                      "  Country: ${senderCountryCtrl.text} (ID: $selectedCountryId)",
                    );
                    logger.i(
                      "  State: ${senderStateCtrl.text} (ID: $selectedStateId)",
                    );
                    logger.i(
                      "  District: ${senderDistrictCtrl.text} (ID: $selectedDistrictId)",
                    );
                    logger.i("  Coordinates: $senderLat, $senderLng");
                    logger.i("  Address ID: $selectedSenderAddressId");

                    logger.i("📦 RECEIVER DETAILS:");
                    logger.i("  Name: ${receiverNameCtrl.text}");
                    logger.i("  Phone: ${receiverPhoneCtrl.text}");
                    logger.i("  Address: ${receiverAddressCtrl.text}");
                    logger.i("  Landmark: ${receiverLandmarkCtrl.text}");
                    logger.i("  Zip: ${receiverZipCtrl.text}");
                    logger.i(
                      "  Country: ${receiverCountryCtrl.text} (ID: $selectedReceiverCountryId)",
                    );
                    logger.i(
                      "  State: ${receiverStateCtrl.text} (ID: $selectedReceiverStateId)",
                    );
                    logger.i(
                      "  District: ${receiverDistrictCtrl.text} (ID: $selectedReceiverDistrictId)",
                    );
                    logger.i("  Coordinates: $receiverLat, $receiverLng");
                    logger.i("  Address ID: $selectedReceiverAddressId");

                    logger.i("User ID: ${apiService.currentUserId}");
                    logger.i(
                      "Last Created Product ID: ${apiService.lastCreatedProductId}",
                    );

                    if (nameCtrl.text.isEmpty) {
                      logger.w("⚠️ Product name is empty");
                      _showErrorSnackBar("Please enter product name");
                      return;
                    }

                    if (volumeCtrl.text.isEmpty) {
                      logger.w("⚠️ Volume is empty");
                      _showErrorSnackBar("Please enter volume");
                      return;
                    }
                    if (senderAddressCtrl.text.isEmpty) {
                      logger.w("⚠️ Sender address is empty");
                      _showErrorSnackBar("Please enter sender address");
                      return;
                    }

                    if (senderDistrictCtrl.text.isEmpty) {
                      logger.w("⚠️ Sender district is empty");
                      _showErrorSnackBar("Please select sender district");
                      return;
                    }

                    if (senderStateCtrl.text.isEmpty) {
                      logger.w("⚠️ Sender state is empty");
                      _showErrorSnackBar("Please select sender state");
                      return;
                    }

                    if (senderCountryCtrl.text.isEmpty) {
                      logger.w("⚠️ Sender country is empty");
                      _showErrorSnackBar("Please select sender country");
                      return;
                    }

                    if (senderZipCtrl.text.isEmpty) {
                      logger.w("⚠️ Sender zip code is empty");
                      _showErrorSnackBar("Please enter sender zip code");
                      return;
                    }

                    if (selectedReceiverCountryId == null) {
                      logger.e(
                        "❌ Receiver country ID is null - Country text: ${receiverCountryCtrl.text}",
                      );

                      if (receiverCountryCtrl.text.isNotEmpty) {
                        logger.i(
                          "Attempting to find country ID from text: ${receiverCountryCtrl.text}",
                        );
                        final countryMatch = countries.firstWhere(
                          (c) =>
                              c['name']?.toLowerCase() ==
                              receiverCountryCtrl.text.toLowerCase(),
                          orElse: () {
                            logger.w(
                              "Country not found in list. Available countries: ${countries.map((c) => c['name']).toList()}",
                            );
                            return null;
                          },
                        );

                        if (countryMatch != null) {
                          selectedReceiverCountryId = countryMatch['id'];
                          logger.i(
                            "✅ Found country ID: $selectedReceiverCountryId",
                          );
                        } else {
                          _showErrorSnackBar(
                            "Please select receiver country from the list",
                          );
                          return;
                        }
                      } else {
                        _showErrorSnackBar("Please select receiver country");
                        return;
                      }
                    }

                    if (selectedReceiverStateId == null) {
                      logger.e(
                        "❌ Receiver state ID is null - State text: ${receiverStateCtrl.text}",
                      );

                      if (receiverStateCtrl.text.isNotEmpty &&
                          selectedReceiverCountryId != null) {
                        logger.i("Attempting to find state ID from text");
                        if (receiverStates.isEmpty) {
                          await _fetchReceiverStates(
                            countryId: selectedReceiverCountryId!,
                            page: 1,
                            search: null,
                          );
                        }

                        final stateMatch = receiverStates.firstWhere(
                          (s) =>
                              s['name']?.toLowerCase() ==
                              receiverStateCtrl.text.toLowerCase(),
                          orElse: () {
                            logger.w(
                              "State not found in list. Available states: ${receiverStates.map((s) => s['name']).toList()}",
                            );
                            return null;
                          },
                        );

                        if (stateMatch != null) {
                          selectedReceiverStateId = stateMatch['id'];
                          logger.i(
                            "✅ Found state ID: $selectedReceiverStateId",
                          );
                        } else {
                          _showErrorSnackBar(
                            "Please select receiver state from the list",
                          );
                          return;
                        }
                      } else {
                        _showErrorSnackBar("Please select receiver state");
                        return;
                      }
                    }

                    if (selectedReceiverDistrictId == null) {
                      logger.e(
                        "❌ Receiver district ID is null - District text: ${receiverDistrictCtrl.text}",
                      );

                      if (receiverDistrictCtrl.text.isNotEmpty &&
                          selectedReceiverStateId != null) {
                        logger.i("Attempting to find district ID from text");
                        if (receiverDistricts.isEmpty) {
                          await _fetchReceiverDistricts(
                            stateId: selectedReceiverStateId!,
                            page: 1,
                            search: null,
                          );
                        }

                        final districtMatch = receiverDistricts.firstWhere(
                          (d) =>
                              d['name']?.toLowerCase() ==
                              receiverDistrictCtrl.text.toLowerCase(),
                          orElse: () {
                            logger.w(
                              "District not found in list. Available districts: ${receiverDistricts.map((d) => d['name']).toList()}",
                            );
                            return null;
                          },
                        );

                        if (districtMatch != null) {
                          selectedReceiverDistrictId = districtMatch['id'];
                          logger.i(
                            "✅ Found district ID: $selectedReceiverDistrictId",
                          );
                        } else {
                          _showErrorSnackBar(
                            "Please select receiver district from the list",
                          );
                          return;
                        }
                      } else {
                        _showErrorSnackBar("Please select receiver district");
                        return;
                      }
                    }

                    if (senderLat == null || senderLng == null) {
                      logger.w("⚠️ Sender coordinates missing");
                      _showErrorSnackBar(
                        "Please select pickup location on map",
                      );
                      return;
                    }

                    if (receiverLat == null || receiverLng == null) {
                      logger.w("⚠️ Receiver coordinates missing");
                      _showErrorSnackBar(
                        "Please select delivery location on map",
                      );
                      return;
                    }

                    if (selectedSenderAddressId == null) {
                      logger.w("⚠️ Sender address ID missing");
                      _showErrorSnackBar("Please select a sender address");
                      return;
                    }

                    if (selectedReceiverAddressId == null) {
                      logger.w("⚠️ Receiver address ID missing");
                      _showErrorSnackBar("Please select a receiver address");
                      return;
                    }

                    if (!mounted) return;

                    logger.i("✅ All validations passed. Creating product...");
                    setState(() => isCreatingShipment = true);

                    try {
                      final productSuccess = await apiService.addProduct(
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        volume: volumeCtrl.text,
                        actualWeight: weightCtrl.text,
                        image: productImage,
                      );

                      if (!productSuccess) {
                        logger.e("❌ Product creation failed");
                        _showErrorSnackBar("Product creation failed");
                        setState(() => isCreatingShipment = false);
                        return;
                      }

                      logger.i(
                        "✅ Product created successfully. ID: ${apiService.lastCreatedProductId}",
                      );

                      if (apiService.lastCreatedProductId == null) {
                        logger.e("❌ Product ID is null after creation");
                        _showErrorSnackBar("Failed to get product ID");
                        setState(() => isCreatingShipment = false);
                        return;
                      }

                      if (apiService.currentUserId == null) {
                        logger.e("❌ User ID is null");
                        _showErrorSnackBar(
                          "User session error. Please login again",
                        );
                        setState(() => isCreatingShipment = false);
                        return;
                      }

                      logger.i("📡 Creating pickup request with:");
                      logger.i("  receiverId: $selectedReceiverAddressId");
                      logger.i(
                        "  productId: ${apiService.lastCreatedProductId}",
                      );
                      logger.i("  senderAddressId: $selectedSenderAddressId");
                      logger.i(
                        "  receiverAddressId: $selectedReceiverAddressId",
                      );

                      final pickupResponse = await apiService
                          .createPickupRequest(
                            receiverId: selectedReceiverAddressId!,
                            productId: apiService.lastCreatedProductId!,
                            senderAddressId: selectedSenderAddressId!,
                            receiverAddressId: selectedReceiverAddressId!,
                          );

                      if (pickupResponse == null) {
                        logger.e(
                          "❌ Pickup request creation failed - null response",
                        );
                        _showErrorSnackBar("Failed to create shipment");
                        setState(() => isCreatingShipment = false);
                        return;
                      }

                      logger.i("✅ Pickup request created successfully");
                      logger.i("Response: $pickupResponse");

                      dynamic pickupId;
                      String? orderNumber;

                     
                      // ignore: unnecessary_type_check
                      if (pickupResponse is Map) {
                        if (pickupResponse.containsKey("data") &&
                            pickupResponse["data"] is Map) {
                          pickupId = pickupResponse["data"]["id"];
                          orderNumber = pickupResponse["data"]["pickup_no"];
                          logger.i(
                            "📦 Extracted from data wrapper - ID: $pickupId, Order: $orderNumber",
                          );
                        } else {
                          pickupId = pickupResponse["id"];
                          orderNumber = pickupResponse["pickup_no"];
                          logger.i(
                            "📦 Extracted from root - ID: $pickupId, Order: $orderNumber",
                          );
                        }
                      }

                      if (pickupId == null) {
                        logger.e("❌ Pickup ID is null in response");
                        logger.e("Response keys: ${pickupResponse?.keys}");
                        _showErrorSnackBar("Invalid response from server");
                        setState(() => isCreatingShipment = false);
                        return;
                      }

                      logger.i(
                        "🎉 Shipment created! ID: $pickupId, Order #: $orderNumber",
                      );

                      if (!mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderSuccessWrapper(
                            productId: apiService.lastCreatedProductId,
                            pickupId: pickupId,
                            orderNumber: orderNumber,
                          ),
                        ),
                      );
                    } catch (e, stackTrace) {
                      logger.e("❌ Error during shipment creation: $e");
                      logger.e("Stack trace: $stackTrace");
                      _showErrorSnackBar("An error occurred: ${e.toString()}");
                      setState(() => isCreatingShipment = false);
                    }
                  },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
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
                    border: Border.all(color: ColorConstants.red, width: 6),
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
                  child: Icon(Icons.send, color: Colors.red, size: 28),
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
                          color: ColorConstants.red,
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
    String? locationName,
    double? lat,
    double? lng,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                color: Colors.black.withOpacity(0.1),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
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
                  _buildInfoRow(Icons.phone, phone, primaryColor),
                  _buildInfoRow(Icons.location_on, address, primaryColor),
                  if (landmark.isNotEmpty)
                    _buildInfoRow(Icons.landscape, landmark, primaryColor),
                  _buildInfoRow(Icons.pin_drop, zip, primaryColor),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.map,
                          "$district, $state, $country",
                          primaryColor,
                          isBold: true,
                        ),
                        if (locationName != null && locationName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildInfoRow(
                              Icons.location_pin,
                              locationName,
                              primaryColor,
                            ),
                          ),
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
                        backgroundColor: Colors.black.withOpacity(0.1),
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

    if (countries.isEmpty && !isCountryLoading) {
      _loadCountries();
    }

    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext parentContext) {
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
                              final result = await Navigator.push(
                                sheetContext,
                                MaterialPageRoute(
                                  builder: (_) => const MapPickerScreen(),
                                ),
                              );

                              if (result != null) {
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
                          _buildLocationSelectorButtons(
                            setModalState,
                            isSender: true,
                          ),
                          const SizedBox(height: 24),
                          _buildAttractiveSaveButton(
                            color: AddressColors.senderPrimary,
                            onPressed: () async {
                              if (senderNameCtrl.text.isEmpty ||
                                  selectedDistrictId == null ||
                                  senderLat == null) {
                                _showErrorSnackBar(
                                  "Please complete all sender details",
                                );
                                return;
                              }

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
      if (addressId == null || !mounted) return;

      setState(() {
        isSenderCompleted = true;
        selectedSenderAddressId = addressId;
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
    if (countries.isEmpty && !isCountryLoading) {
      _loadCountries();
    }
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
                          _buildLocationSelectorButtons(
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
                                    district: selectedReceiverDistrictId!,
                                    state: selectedReceiverStateId!,
                                    country: selectedReceiverCountryId!,
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _openAttractiveSenderBottomSheet();
                      });
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _openAttractiveReceiverBottomSheet();
                      });
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

  Widget _buildLocationSelectorButtons(
    StateSetter setModalState, {
    required bool isSender,
  }) {
    return Column(
      children: [
  
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () async {
              // ignore: unused_local_variable
              final selected = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CountrySelector(
                  selectedId: isSender
                      ? selectedCountryId
                      : selectedReceiverCountryId,
                  color: isSender
                      ? AddressColors.senderPrimary
                      : AddressColors.receiverPrimary,
                  onSelected: (country) async {
                    if (isSender) {
                      setState(() {
                        selectedCountryId = country['id'];
                        senderCountryCtrl.text = country['name'];
                        selectedStateId = null;
                        selectedDistrictId = null;
                      });

                      states.clear();
                      districts.clear();

                      if (selectedCountryId != null) {
                        await _fetchSenderStates(
                          countryId: selectedCountryId!,
                          page: 1,
                          search: null,
                        );
                      }
                    } else {
                      setState(() {
                        selectedReceiverCountryId = country['id'];
                        receiverCountryCtrl.text = country['name'];
                        selectedReceiverStateId = null;
                        selectedReceiverDistrictId = null;
                      });
                      receiverStates.clear();
                      receiverDistricts.clear();

                      if (selectedReceiverCountryId != null) {
                        await _fetchReceiverStates(
                          countryId: selectedReceiverCountryId!,
                          page: 1,
                          search: null,
                        );
                      }
                    }
                    setModalState(() {});
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
                  color:
                      (isSender
                              ? AddressColors.senderPrimary
                              : AddressColors.receiverPrimary)
                          .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: isSender
                        ? AddressColors.senderPrimary
                        : AddressColors.receiverPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Country",
                          style: TextStyle(
                            fontSize: 12,
                            color: AddressColors.textSecondary,
                          ),
                        ),
                        Text(
                          (isSender
                                      ? senderCountryCtrl.text
                                      : receiverCountryCtrl.text)
                                  .isEmpty
                              ? "Select Country"
                              : (isSender
                                    ? senderCountryCtrl.text
                                    : receiverCountryCtrl.text),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                (isSender
                                        ? senderCountryCtrl.text
                                        : receiverCountryCtrl.text)
                                    .isEmpty
                                ? AddressColors.textSecondary
                                : AddressColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isSender
                        ? AddressColors.senderPrimary
                        : AddressColors.receiverPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),

        if ((isSender && selectedCountryId != null) ||
            (!isSender && selectedReceiverCountryId != null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                // ignore: unused_local_variable
                final selected =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => StateSelector(
                        selectedId: isSender
                            ? selectedStateId
                            : selectedReceiverStateId,
                        countryId: isSender
                            ? selectedCountryId!
                            : selectedReceiverCountryId!,
                        color: isSender
                            ? AddressColors.senderPrimary
                            : AddressColors.receiverPrimary,
                        onSelected: (state) async {
                          if (isSender) {
                            setState(() {
                              selectedStateId = state['id'];
                              senderStateCtrl.text = state['name'];
                              selectedDistrictId = null;
                            });
                            districts.clear();

                            if (selectedStateId != null) {
                              await _fetchSenderDistricts(
                                stateId: selectedStateId!,
                                page: 1,
                                search: null,
                              );
                            }
                          } else {
                            setState(() {
                              selectedReceiverStateId = state['id'];
                              receiverStateCtrl.text = state['name'];
                              selectedReceiverDistrictId = null;
                            });
                            receiverDistricts.clear();

                            if (selectedReceiverStateId != null) {
                              await _fetchReceiverDistricts(
                                stateId: selectedReceiverStateId!,
                                page: 1,
                                search: null,
                              );
                            }
                          }
                          setModalState(() {});
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
                    color:
                        (isSender
                                ? AddressColors.senderPrimary
                                : AddressColors.receiverPrimary)
                            .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: isSender
                          ? AddressColors.senderPrimary
                          : AddressColors.receiverPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "State",
                            style: TextStyle(
                              fontSize: 12,
                              color: AddressColors.textSecondary,
                            ),
                          ),
                          Text(
                            (isSender
                                        ? senderStateCtrl.text
                                        : receiverStateCtrl.text)
                                    .isEmpty
                                ? "Select State"
                                : (isSender
                                      ? senderStateCtrl.text
                                      : receiverStateCtrl.text),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  (isSender
                                          ? senderStateCtrl.text
                                          : receiverStateCtrl.text)
                                      .isEmpty
                                  ? AddressColors.textSecondary
                                  : AddressColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isSender
                          ? AddressColors.senderPrimary
                          : AddressColors.receiverPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),

        if ((isSender && selectedStateId != null) ||
            (!isSender && selectedReceiverStateId != null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () async {
                // ignore: unused_local_variable
                final selected =
                    await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DistrictSelector(
                        selectedId: isSender
                            ? selectedDistrictId
                            : selectedReceiverDistrictId,
                        stateId: isSender
                            ? selectedStateId!
                            : selectedReceiverStateId!,
                        color: isSender
                            ? AddressColors.senderPrimary
                            : AddressColors.receiverPrimary,
                        onSelected: (district) {
                          if (isSender) {
                            setState(() {
                              selectedDistrictId = district['id'];
                              senderDistrictCtrl.text = district['name'];
                            });
                          } else {
                            setState(() {
                              selectedReceiverDistrictId = district['id'];
                              receiverDistrictCtrl.text = district['name'];
                            });
                          }
                          setModalState(() {});
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
                    color:
                        (isSender
                                ? AddressColors.senderPrimary
                                : AddressColors.receiverPrimary)
                            .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: isSender
                          ? AddressColors.senderPrimary
                          : AddressColors.receiverPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "District",
                            style: TextStyle(
                              fontSize: 12,
                              color: AddressColors.textSecondary,
                            ),
                          ),
                          Text(
                            (isSender
                                        ? senderDistrictCtrl.text
                                        : receiverDistrictCtrl.text)
                                    .isEmpty
                                ? "Select District"
                                : (isSender
                                      ? senderDistrictCtrl.text
                                      : receiverDistrictCtrl.text),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  (isSender
                                          ? senderDistrictCtrl.text
                                          : receiverDistrictCtrl.text)
                                      .isEmpty
                                  ? AddressColors.textSecondary
                                  : AddressColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isSender
                          ? AddressColors.senderPrimary
                          : AddressColors.receiverPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
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
                        color: Colors.black.withOpacity(0.1),
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
        label: Text(title, style: const TextStyle(color: Colors.white)),
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
