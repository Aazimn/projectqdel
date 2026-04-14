import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

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
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search...",
        hintStyle: TextStyle(color: Colors.white),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
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
  final Logger logger = Logger();
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

  File? editProductImage;
  final ImagePicker _imagePicker = ImagePicker();



  Future<void> _loadReceiverStates(int countryId) async {
    setState(() => isReceiverStateLoading = true);
    try {
      logger.i("📡 Fetching receiver states for countryId=$countryId");
      final response = await apiService.getStatesByCountry(
        countryId: countryId,
        page: 1,
      );

      if (response is List) {
        receiverStates = response;
      } else if (response is Map) {
        receiverStates = (response['results'] as List?) ?? [];
      }
      logger.i("✅ Loaded ${receiverStates.length} receiver states");
    } catch (e) {
      logger.e("Receiver State load error: $e");
      receiverStates = [];
    } finally {
      setState(() => isReceiverStateLoading = false);
    }
  }

  Future<void> _loadReceiverDistricts(int stateId) async {
    setState(() => isReceiverDistrictLoading = true);
    try {
      logger.i("📡 Fetching receiver districts for stateId=$stateId");
      final response = await apiService.getDistrictsByState(
        stateId: stateId,
        page: 1,
      );

      if (response is List) {
        receiverDistricts = response;
      } else if (response is Map) {
        receiverDistricts = (response['results'] as List?) ?? [];
      }
      logger.i("✅ Loaded ${receiverDistricts.length} receiver districts");
    } catch (e) {
      logger.e("Receiver District load error: $e");
      receiverDistricts = [];
    } finally {
      setState(() => isReceiverDistrictLoading = false);
    }
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
    await _fetchCountries(page: 1, loadAll: true);
    isInitializingDefaults = false;
    setState(() {});
  }

  Future<void> _fetchCountries({
    int page = 1,
    String? search,
    bool loadAll = false,
  }) async {
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
      setState(() {
        if (page == 1) {
          countries = data;
        } else {
          countries.addAll(data);
        }
        _countryPage = page;
        _countrySearchQuery = search ?? '';
        _countryHasNext = hasNext;
      });

      if (loadAll && hasNext) {
        await _fetchCountries(page: page + 1, search: search, loadAll: true);
      }
    } catch (e) {
      logger.e("❌ Country load error: $e");
      setState(() {
        if (page == 1) countries = [];
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
    }

    setState(() {
      senderAddress = combined;
    });

    senderNameCtrl.text = combined['sender_name'] ?? '';
    senderPhoneCtrl.text = combined['phone_number'] ?? '';
    senderAddressCtrl.text = combined['address'] ?? '';
    senderLandmarkCtrl.text = combined['landmark'] ?? '';
    senderZipCtrl.text = combined['zip_code'] ?? '';

    String existingAddress = combined['address'] ?? '';

    if (senderLatitude != null && senderLongitude != null) {
      try {
        String realLocationName = await _getLocationName(
          senderLatitude!,
          senderLongitude!,
        );

        if (realLocationName.isNotEmpty &&
            (existingAddress.length < 10 ||
                existingAddress == "200" ||
                existingAddress.isEmpty)) {
          setState(() {
            senderLocationName = realLocationName;
            if (senderAddress != null) {
              senderAddress!['address'] = realLocationName;
            }
          });
          debugPrint(
            "📍 Got real sender location from coordinates: $senderLocationName",
          );
        } else {
          setState(() {
            senderLocationName = existingAddress;
          });
          debugPrint("📍 Keeping existing sender address: $senderLocationName");
        }
      } catch (e) {
        debugPrint("Error getting location name: $e");
        setState(() {
          senderLocationName = existingAddress.isNotEmpty
              ? existingAddress
              : "Location at ${senderLatitude!.toStringAsFixed(4)}, ${senderLongitude!.toStringAsFixed(4)}";
        });
      }
    } else {
      setState(() {
        senderLocationName = existingAddress.isNotEmpty
            ? existingAddress
            : "Location not available";
      });
    }

    debugPrint("📌 Final sender location name: $senderLocationName");
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'QDelApp/1.0', 'Accept-Language': 'en'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          String locationName = data['display_name'];
          debugPrint("📍 Nominatim geocoded: $locationName");
          return locationName;
        }
      }
    } catch (e) {
      debugPrint("Nominatim geocoding error: $e");
    }

    return "Location at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
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
    String existingAddress = combinedAddress['address_text'] ?? '';
    if (existingAddress.isNotEmpty &&
        !existingAddress.startsWith('Location at') &&
        existingAddress.contains(',')) {
      setState(() {
        receiverLocationName = existingAddress;
      });
      debugPrint(
        "📍 Using existing descriptive receiver location: $receiverLocationName",
      );
    } else if (existingAddress.isNotEmpty &&
        !existingAddress.startsWith('Location at') &&
        !existingAddress.contains(',')) {
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
            receiverLocationName = existingAddress;
          });
        }
      } else {
        setState(() {
          receiverLocationName = existingAddress;
        });
      }
    } else if (receiverLatitude != null && receiverLongitude != null) {
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
              "Location at $receiverLatitude, $receiverLongitude";
        });
      }
    } else {
      receiverLocationName = "Location not available";
    }

    debugPrint("✅ Loaded receiver address with ID: ${combinedAddress['id']}");
    debugPrint("📍 Final receiver location name: $receiverLocationName");
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
        color: ColorConstants.red,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.hourglass_top,
              color: ColorConstants.red,
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    const Text(
                      "Edit Product",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Image Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.image, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "Product Image",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              // Show image picker options
                              final picked = await _showImagePickerOptions();
                              if (picked != null) {
                                setModalState(() {
                                  editProductImage = picked;
                                });
                              }
                            },
                            child: Container(
                              height: 150,
                              margin: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: editProductImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        editProductImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : (product?['images'] != null &&
                                            product!['images'].isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              "${apiService.baseurl}${product!['images'][0]['image']}",
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            "Tap to change image",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "Tap to add product image",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product Details Fields
                    _textField("Product Name", nameCtrl),
                    const SizedBox(height: 12),
                    _textField("Description", descCtrl, maxLines: 3),
                    const SizedBox(height: 12),
                    _textField("Weight (kg)", weightCtrl, isNumber: true),
                    const SizedBox(height: 12),
                    _textField("Volume (cm³)", volumeCtrl, isNumber: true),

                    const SizedBox(height: 24),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateProductWithImage();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Update Product",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<File?> _showImagePickerOptions() async {
    final completer = Completer<File?>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: const Text("Take Photo"),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (picked != null) {
                  completer.complete(File(picked.path));
                } else {
                  completer.complete(null);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (picked != null) {
                  completer.complete(File(picked.path));
                } else {
                  completer.complete(null);
                }
              },
            ),
          ],
        ),
      ),
    );

    return completer.future;
  }

  Future<void> _updateProductWithImage() async {
    final success = await apiService.updateProduct(
      productId: widget.productId,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      actualWeight: weightCtrl.text.trim(),
      volume: volumeCtrl.text.trim(),
      productImage: editProductImage,
    );

    if (!mounted) return;

    if (success) {
      // Reset the image after successful upload
      setState(() {
        editProductImage = null;
      });
      await _loadProduct();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Product updated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Failed to update product"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
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

    if (title == "SENDER DETAILS" &&
        senderLocationName != null &&
        senderLocationName!.isNotEmpty) {
      displayAddress = senderLocationName!;
      debugPrint("📌 Using sender location name: $displayAddress");
    } else if (title == "RECEIVER DETAILS" &&
        receiverLocationName != null &&
        receiverLocationName!.isNotEmpty) {
      displayAddress = receiverLocationName!;
      debugPrint("📌 Using receiver location name: $displayAddress");
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
            crossAxisAlignment: CrossAxisAlignment.start,
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

  Future<void> _openEditReceiverSheet() async {
    if (!mounted) return;

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
                                await _applyReceiverAddress(addr);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Receiver address updated!"),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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

  Future<void> _applySenderAddress(Map<String, dynamic> addr) async {
    logger.i("🔵 Applying sender address: ${addr['id']}");

    senderNameCtrl.text = addr["sender_name"] ?? "";
    senderPhoneCtrl.text = addr["phone_number"] ?? "";
    senderAddressCtrl.text = addr["address"] ?? "";
    senderLandmarkCtrl.text = addr["landmark"] ?? "";
    senderZipCtrl.text = addr["zip_code"] ?? "";

    senderLatitude = double.tryParse(addr["latitude"]?.toString() ?? "");
    senderLongitude = double.tryParse(addr["longitude"]?.toString() ?? "");

    if (senderLatitude != null && senderLongitude != null) {
      try {
        String locationName = await _getLocationName(
          senderLatitude!,
          senderLongitude!,
        );
        setState(() {
          senderLocationName = locationName;
          senderAddressCtrl.text = locationName;
        });
      } catch (e) {
        setState(() {
          senderLocationName =
              "Location at ${senderLatitude?.toStringAsFixed(4) ?? '?'}, ${senderLongitude?.toStringAsFixed(4) ?? '?'}";
        });
      }
    }

    senderCountryCtrl.text = addr["country"] ?? "";
    senderStateCtrl.text = addr["state"] ?? "";
    senderDistrictCtrl.text = addr["district"] ?? "";

    setState(() {
      selectedCountryId = null;
      selectedStateId = null;
      selectedDistrictId = null;
    });

    if (addr["country"] != null && addr["country"].isNotEmpty) {
      try {
        final countryMatch = countries.firstWhere(
          (c) => c['name'] == addr["country"],
          orElse: () => null,
        );

        if (countryMatch != null) {
          setState(() {
            selectedCountryId = countryMatch['id'];
          });

          if (selectedCountryId != null) {
            await _loadStates(selectedCountryId!);

            if (addr["state"] != null && addr["state"].isNotEmpty) {
              final stateMatch = states.firstWhere(
                (s) => s['name'] == addr["state"],
                orElse: () => null,
              );

              if (stateMatch != null) {
                setState(() {
                  selectedStateId = stateMatch['id'];
                });

                if (selectedStateId != null) {
                  await _loadDistricts(selectedStateId!);

                  if (addr["district"] != null && addr["district"].isNotEmpty) {
                    final districtMatch = districts.firstWhere(
                      (d) => d['name'] == addr["district"],
                      orElse: () => null,
                    );

                    if (districtMatch != null) {
                      setState(() {
                        selectedDistrictId = districtMatch['id'];
                      });
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        logger.e("Error in _applySenderAddress: $e");
      }
    }

    await _updateSenderAddress();
  }

  Future<void> _applyReceiverAddress(Map<String, dynamic> addr) async {
    logger.i("🔵 Applying receiver address: ${addr['id']}");

    receiverNameCtrl.text = addr["receiver_name"] ?? "";
    receiverPhoneCtrl.text = addr["receiver_phone"] ?? "";
    receiverAddressCtrl.text = addr["address_text"] ?? "";
    receiverLandmarkCtrl.text = addr["landmark"] ?? "";
    receiverZipCtrl.text = addr["zip_code"] ?? "";

    receiverLatitude = double.tryParse(addr["latitude"]?.toString() ?? "");
    receiverLongitude = double.tryParse(addr["longitude"]?.toString() ?? "");

    if (receiverLatitude != null && receiverLongitude != null) {
      try {
        String locationName = await _getLocationName(
          receiverLatitude!,
          receiverLongitude!,
        );
        setState(() {
          receiverLocationName = locationName;
          receiverAddressCtrl.text = locationName;
        });
      } catch (e) {
        setState(() {
          receiverLocationName =
              "Location at ${receiverLatitude?.toStringAsFixed(4) ?? '?'}, ${receiverLongitude?.toStringAsFixed(4) ?? '?'}";
        });
      }
    }

    receiverCountryCtrl.text = addr["country"] ?? "";
    receiverStateCtrl.text = addr["state"] ?? "";
    receiverDistrictCtrl.text = addr["district"] ?? "";

    // Find and set the IDs - with null safety
    setState(() {
      selectedReceiverCountryId = null;
      selectedReceiverStateId = null;
      selectedReceiverDistrictId = null;
    });

    // Find country
    if (addr["country"] != null && addr["country"].isNotEmpty) {
      try {
        final countryMatch = countries.firstWhere(
          (c) => c['name'] == addr["country"],
          orElse: () => null,
        );

        if (countryMatch != null) {
          setState(() {
            selectedReceiverCountryId = countryMatch['id'];
          });

          if (selectedReceiverCountryId != null) {
            await _loadReceiverStates(selectedReceiverCountryId!);

            // Find state
            if (addr["state"] != null && addr["state"].isNotEmpty) {
              final stateMatch = receiverStates.firstWhere(
                (s) => s['name'] == addr["state"],
                orElse: () => null,
              );

              if (stateMatch != null) {
                setState(() {
                  selectedReceiverStateId = stateMatch['id'];
                });

                if (selectedReceiverStateId != null) {
                  await _loadReceiverDistricts(selectedReceiverStateId!);
                  if (addr["district"] != null && addr["district"].isNotEmpty) {
                    final districtMatch = receiverDistricts.firstWhere(
                      (d) => d['name'] == addr["district"],
                      orElse: () => null,
                    );

                    if (districtMatch != null) {
                      setState(() {
                        selectedReceiverDistrictId = districtMatch['id'];
                      });
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        logger.e("Error in _applyReceiverAddress: $e");
      }
    }
    await _updateReceiverAddress();
  }

  void _resetSenderForm() {
    senderNameCtrl.clear();
    senderPhoneCtrl.clear();
    senderAddressCtrl.clear();
    senderLandmarkCtrl.clear();
    senderZipCtrl.clear();

    senderLatitude = null;
    senderLongitude = null;
    senderLocationName = null;

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

    receiverLatitude = null;
    receiverLongitude = null;
    receiverLocationName = null;

    selectedReceiverCountryId = savedCountryId;
    selectedReceiverStateId = savedStateId;
    selectedReceiverDistrictId = savedDistrictId;

    receiverStates.clear();
    receiverDistricts.clear();

    receiverCountryCtrl.text = senderCountryCtrl.text;
    receiverStateCtrl.clear();
    receiverDistrictCtrl.clear();
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

  Widget _buildAttractiveAddressListItem({
    required Map<String, dynamic> addr,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
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
              color: Colors.white,
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

  Future<void> _openAttractiveSenderBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                "Add Sender Address",
                AddressColors.senderPrimary,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(children: [
                 
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAttractiveReceiverBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(children: [
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        String? currentLocationName = receiverLocationName;

        await _loadReceiverAddress();
        if (currentLocationName != null &&
            !currentLocationName.startsWith('Location at')) {
          setState(() {
            receiverLocationName = currentLocationName;
            if (receiverAddress != null) {
              receiverAddress!['address_text'] = currentLocationName;
            }
          });
        }

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
    if (!mounted) return;
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
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Sender address updated!"),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
      String? currentLocationName = senderLocationName;

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
        if (currentLocationName != null &&
            !currentLocationName.startsWith('Location at') &&
            currentLocationName != 'Selected location' &&
            currentLocationName != 'Saved location') {
          setState(() {
            senderLocationName = currentLocationName;
            if (senderAddress != null) {
              senderAddress!['address'] = currentLocationName;
            }
          });
        }

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
          backgroundColor: ColorConstants.red,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await apiService.cancelOrder(
                pickupId: widget.pickupId,
              );

              if (!mounted) return;

              Navigator.pop(context);

              if (success != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Order cancelled successfully"),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClientDashboard(initialIndex: 2),
                  ),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to cancel order. Please try again."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
