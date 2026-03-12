import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/map_picker.dart';
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
          _buildPaginationHeader(),
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
        mainAxisAlignment: MainAxisAlignment.end,
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
          _buildPaginationHeader(),
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
        mainAxisAlignment: MainAxisAlignment.end,
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
          _buildPaginationHeader(),
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
        mainAxisAlignment: MainAxisAlignment.end,
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
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
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


  Future<void> _fetchReceiverStates({
    required int countryId,
    required int page,
    String? search,
  }) async {
    setState(() => isReceiverStateLoading = true);
    try {
      logger.i(
        "📡 Fetching receiver states countryId=$countryId page=$page search=$search",
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

      logger.i("✅ Receiver states loaded: ${data.length}, hasNext=$hasNext");

      setState(() {
        receiverStates = data;
        _receiverStatePage = page;
        _receiverStateSearchQuery = search ?? '';
        _receiverStateHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ Receiver state load error: $e");
      setState(() {
        receiverStates = [];
        _receiverStateHasNext = false;
      });
    } finally {
      setState(() => isReceiverStateLoading = false);
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
        "📡 Fetching receiver districts stateId=$stateId page=$page search=$search",
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

      logger.i("✅ Receiver districts loaded: ${data.length}, hasNext=$hasNext");

      setState(() {
        receiverDistricts = data;
        _receiverDistrictPage = page;
        _receiverDistrictSearchQuery = search ?? '';
        _receiverDistrictHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ Receiver district load error: $e");
      setState(() {
        receiverDistricts = [];
        _receiverDistrictHasNext = false;
      });
    } finally {
      setState(() => isReceiverDistrictLoading = false);
    }
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
                child: const Text(
                  "Update Product",
                  style: TextStyle(color: ColorConstants.white),
                ),
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
    final currentCountryId = isSender
        ? selectedCountryId
        : selectedReceiverCountryId;
    final currentStateId = isSender ? selectedStateId : selectedReceiverStateId;
    final currentDistrictId = isSender
        ? selectedDistrictId
        : selectedReceiverDistrictId;

    final countryCtrl = isSender ? senderCountryCtrl : receiverCountryCtrl;
    final stateCtrl = isSender ? senderStateCtrl : receiverStateCtrl;
    final districtCtrl = isSender ? senderDistrictCtrl : receiverDistrictCtrl;

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
                  selectedId: currentCountryId,
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
                          countryCtrl.text.isEmpty
                              ? "Select Country"
                              : countryCtrl.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: countryCtrl.text.isEmpty
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

        if (currentCountryId != null)
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
                        selectedId: currentStateId,
                        countryId: currentCountryId,
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
                            stateCtrl.text.isEmpty
                                ? "Select State"
                                : stateCtrl.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: stateCtrl.text.isEmpty
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
        if (currentStateId != null)
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
                        selectedId: currentDistrictId,
                        stateId: currentStateId,
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
                            districtCtrl.text.isEmpty
                                ? "Select District"
                                : districtCtrl.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: districtCtrl.text.isEmpty
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
                  top: 25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ColorConstants.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: const Text(
                          "Edit Receiver Address",
                          style: TextStyle(
                            color: ColorConstants.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            builder: (_) => MapPickerScreen(
                              initialLatitude: receiverLatitude,
                              initialLongitude: receiverLongitude,
                              initialLocationName: receiverLocationName,
                            ),
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

                          receiverAddressCtrl.text = result['locationName'];
                        }
                      },
                      Colors.red,
                      locationName: receiverLocationName,
                    ),
                    const SizedBox(height: 16),
                    _buildLocationSelectorButtons(
                      setModalState,
                      isSender: false,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateReceiverAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        "Update Address",
                        style: TextStyle(color: ColorConstants.white),
                      ),
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
                  top: 25,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: double.infinity,
                      height: 50,

                      child: Center(
                        child: const Text(
                          "Edit Sender Address",
                          style: TextStyle(
                            fontSize: 18,
                            color: ColorConstants.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            builder: (_) => MapPickerScreen(
                              initialLatitude: senderLatitude,
                              initialLongitude: senderLongitude,
                              initialLocationName: senderLocationName,
                            ),
                          ),
                        );

                        if (result != null) {
                          setModalState(() {
                            senderLatitude = result['latitude'];
                            senderLongitude = result['longitude'];
                            senderLocationName = result['locationName'];
                          });

                          setState(() {
                            senderLocationName = result['locationName'];
                            if (senderAddress != null) {
                              senderAddress!['address'] =
                                  result['locationName'];
                            }
                          });

                          senderAddressCtrl.text = result['locationName'];
                        }
                      },
                      Colors.red,
                      locationName: senderLocationName,
                    ),

                    const SizedBox(height: 16),
                    _buildLocationSelectorButtons(
                      setModalState,
                      isSender: true,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateSenderAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        "Update Address",
                        style: TextStyle(color: ColorConstants.white),
                      ),
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

  Future<void> _setSenderDropdownDefaults() async {
    if (senderAddress == null) return;

    debugPrint("🎯 Setting sender defaults with address: $senderAddress");

    final countryName = senderAddress?['country'];
    final stateName = senderAddress?['state'];
    final districtName = senderAddress?['district'];

    debugPrint("🔍 Looking for country: $countryName");

    final country = countries.firstWhere(
      (c) => c['name'] == countryName,
      orElse: () {
        debugPrint("❌ Country not found: $countryName");
        return null;
      },
    );

    if (country != null) {
      setState(() {
        selectedCountryId = country['id'];
        senderCountryCtrl.text = country['name'];
      });

      debugPrint(
        "✅ Found country: ${country['name']} with ID: ${country['id']}",
      );

      await _loadStates(selectedCountryId!);
      await Future.delayed(const Duration(milliseconds: 100));

      debugPrint("🔍 Looking for state: $stateName in ${states.length} states");
      debugPrint("Available states: ${states.map((s) => s['name']).toList()}");

      final state = states.firstWhere(
        (s) => s['name'] == stateName,
        orElse: () {
          debugPrint("❌ State not found: $stateName");
          return null;
        },
      );

      if (state != null) {
        setState(() {
          selectedStateId = state['id'];
          senderStateCtrl.text = state['name'];
        });

        debugPrint("✅ Found state: ${state['name']} with ID: ${state['id']}");
        await _loadDistricts(selectedStateId!);

        await Future.delayed(const Duration(milliseconds: 100));

        debugPrint(
          "🔍 Looking for district: $districtName in ${districts.length} districts",
        );
        debugPrint(
          "Available districts: ${districts.map((d) => d['name']).toList()}",
        );

        final district = districts.firstWhere(
          (d) => d['name'] == districtName,
          orElse: () {
            debugPrint("❌ District not found: $districtName");
            return null;
          },
        );

        if (district != null) {
          setState(() {
            selectedDistrictId = district['id'];
            senderDistrictCtrl.text = district['name'];
          });
          debugPrint(
            "✅ Found district: ${district['name']} with ID: ${district['id']}",
          );
        }
      }
    }

    setState(() {});
  }

  Future<void> _setReceiverDropdownDefaults() async {
    if (receiverAddress == null) return;

    final countryName = receiverAddress?['country'];
    final stateName = receiverAddress?['state'];
    final districtName = receiverAddress?['district'];

    logger.i(
      "Setting receiver defaults - Country: $countryName, State: $stateName, District: $districtName",
    );

    final country = countries.firstWhere(
      (c) => c['name'] == countryName,
      orElse: () {
        logger.w("Country not found: $countryName");
        return null;
      },
    );

    if (country != null) {
      setState(() {
        selectedReceiverCountryId = country['id'];
        receiverCountryCtrl.text = country['name'];
      });

      logger.i("Found country: ${country['name']} with ID: ${country['id']}");
      await _loadReceiverStates(selectedReceiverCountryId!);
      await Future.delayed(const Duration(milliseconds: 100));

      logger.i(
        "Looking for state: $stateName in ${receiverStates.length} states",
      );
      final state = receiverStates.firstWhere(
        (s) => s['name'] == stateName,
        orElse: () {
          logger.w("State not found: $stateName");
          return null;
        },
      );

      if (state != null) {
        setState(() {
          selectedReceiverStateId = state['id'];
          receiverStateCtrl.text = state['name'];
        });

        logger.i("Found state: ${state['name']} with ID: ${state['id']}");
        await _loadReceiverDistricts(selectedReceiverStateId!);
        await Future.delayed(const Duration(milliseconds: 100));

        logger.i(
          "Looking for district: $districtName in ${receiverDistricts.length} districts",
        );
        final district = receiverDistricts.firstWhere(
          (d) => d['name'] == districtName,
          orElse: () {
            logger.w("District not found: $districtName");
            return null;
          },
        );

        if (district != null) {
          setState(() {
            selectedReceiverDistrictId = district['id'];
            receiverDistrictCtrl.text = district['name'];
          });
          logger.i(
            "Found district: ${district['name']} with ID: ${district['id']}",
          );
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
