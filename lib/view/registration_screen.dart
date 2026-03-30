import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/model/shop_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_upload.dart';
import 'package:projectqdel/view/login_screen.dart';
import 'package:projectqdel/view/shop/shop_registration.dart';
import 'package:projectqdel/view/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

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
      color: ColorConstants.red,
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
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search...",
        hintStyle: const TextStyle(color: Colors.white),
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
              color: isSelected ? color : Colors.red.shade200,
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

class RegistrationScreen extends StatefulWidget {
  final String phone;
  const RegistrationScreen({super.key, required this.phone});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final Logger logger = Logger();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  Map<String, dynamic>? selectedCountry;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;

  int? get selectedCountryId => selectedCountry?['id'];
  int? get selectedStateId => selectedState?['id'];
  int? get selectedDistrictId => selectedDistrict?['id'];
  List allStates = [];
  List allDistricts = [];

  int _countryPage = 1;
  bool _countryHasNext = false;
  String _countrySearchQuery = '';

  int _statePage = 1;
  bool _stateHasNext = false;
  String _stateSearchQuery = '';

  bool parcelResponsibilityAccepted = false;
  bool damageLossAccepted = false;
  bool payoutTermsAccepted = false;

  int _districtPage = 1;
  bool _districtHasNext = false;
  String _districtSearchQuery = '';

  List countries = [];
  List states = [];
  List districts = [];
  Map<int, List> stateCache = {};
  Map<int, List> districtCache = {};

  bool isCountryLoading = false;
  bool isStateLoading = false;
  bool isDistrictLoading = false;

  Future<void> loadCountries() async {
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

  Future<void> _fetchStates({
    required int countryId,
    required int page,
    String? search,
  }) async {
    setState(() => isStateLoading = true);
    try {
      logger.i(
        "📡 Fetching states countryId=$countryId page=$page search=$search",
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

      logger.i("✅ States loaded: ${data.length}, hasNext=$hasNext");

      setState(() {
        states = data;
        _statePage = page;
        _stateSearchQuery = search ?? '';
        _stateHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ State load error: $e");
      setState(() {
        states = [];
        _stateHasNext = false;
      });
    } finally {
      setState(() => isStateLoading = false);
    }
  }

  Future<void> _fetchDistricts({
    required int stateId,
    required int page,
    String? search,
  }) async {
    setState(() => isDistrictLoading = true);
    try {
      logger.i(
        "📡 Fetching districts stateId=$stateId page=$page search=$search",
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

      logger.i("✅ Districts loaded: ${data.length}, hasNext=$hasNext");

      setState(() {
        districts = data;
        _districtPage = page;
        _districtSearchQuery = search ?? '';
        _districtHasNext = hasNext;
      });
    } catch (e) {
      logger.e("❌ District load error: $e");
      setState(() {
        districts = [];
        _districtHasNext = false;
      });
    } finally {
      setState(() => isDistrictLoading = false);
    }
  }

  String _customertype = '';

  final _formkey = GlobalKey<FormState>();
  ApiService apiService = ApiService();

  @override
  void dispose() {
    super.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await ApiService.loadSession();
    await loadCountries();
  }

  bool _validateForm() {
    if (_firstName.text.trim().isEmpty) {
      _showValidationToast("First name is required");
      return false;
    }

    if (_lastName.text.trim().isEmpty) {
      _showValidationToast("Last name is required");
      return false;
    }

    if (_email.text.trim().isEmpty) {
      _showValidationToast("Email is required");
      return false;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}',
    ).hasMatch(_email.text.trim())) {
      _showValidationToast("Please enter a valid email address");
      return false;
    }

    if (_customertype.isEmpty) {
      _showValidationToast("Please select a user type (Client or Carrier)");
      return false;
    }

    if (selectedCountryId == null) {
      _showValidationToast("Please select your country");
      return false;
    }

    if (selectedStateId == null) {
      _showValidationToast("Please select your state");
      return false;
    }

    if (selectedDistrictId == null) {
      _showValidationToast("Please select your district");
      return false;
    }

    return true;
  }

  void _showValidationToast(String message) {
    CherryToast.warning(
      title: const Text(
        'Validation Error',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      toastPosition: Position.top,
      animationType: AnimationType.fromTop,
      borderRadius: 10,
      displayIcon: true,
    ).show(context);
  }

  void _showSuccessToast(String message) {
    CherryToast.success(
      title: const Text(
        'Success',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      description: Text(message),
      toastPosition: Position.top,
      animationType: AnimationType.fromTop,
      borderRadius: 10,
      displayIcon: true,
    ).show(context);
  }

  void _showErrorToast(String message) {
    CherryToast.error(
      title: const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
      description: Text(message),
      toastPosition: Position.top,
      animationType: AnimationType.fromTop,
      borderRadius: 10,
      displayIcon: true,
    ).show(context);
  }

  Future<void> register() async {
    if (!_validateForm()) return;

    if (_customertype == 'client') {
      await _registerUser();
    } else if (_customertype == 'shop') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopRegistrationScreen(
            registrationData: ShopRegistrationData(
              phone: widget.phone,
              firstname: _firstName.text.trim(),
              lastname: _lastName.text.trim(),
              email: _email.text.trim(),
              userType: _customertype,
              isExistingUser: false,
              countryId: selectedCountryId,
              stateId: selectedStateId,
              districtId: selectedDistrictId,
              parcelResponsibilityAccepted: parcelResponsibilityAccepted,
              damageLossAccepted: damageLossAccepted,
              payoutTermsAccepted: payoutTermsAccepted,
            ),
          ),
        ),
      );
      // await _registerUser();
    } else if (_customertype == 'carrier') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarrierUploadScreen(
            registrationData: CarrierRegistrationData(
              phone: widget.phone,
              firstname: _firstName.text.trim(),
              lastname: _lastName.text.trim(),
              email: _email.text.trim(),
              userType: _customertype,
              countryId: selectedCountryId,
              stateId: selectedStateId,
              districtId: selectedDistrictId,
              isExistingUser: false,
              parcelResponsibilityAccepted: parcelResponsibilityAccepted,
              damageLossAccepted: damageLossAccepted,
              payoutTermsAccepted: payoutTermsAccepted,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _registerUser() async {
    bool status = await apiService.registration(
      firstname: _firstName.text.trim(),
      lastname: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: widget.phone,
      userType: _customertype,
      countryId: selectedCountryId,
      stateId: selectedStateId,
      districtId: selectedDistrictId,
      parcelResponsibilityAccepted: parcelResponsibilityAccepted,
      damageLossAccepted: damageLossAccepted,
      payoutTermsAccepted: payoutTermsAccepted,
    );

    if (status) {
      await ApiService.saveSession(
        token: ApiService.accessToken!,
        userType: "client",
        approvalStatus: "approved",
        phone: widget.phone,
        firstTime: false,
      );
      final prefs = await SharedPreferences.getInstance();
      if (selectedCountryId != null) {
        await prefs.setInt('country', selectedCountryId!);
      }
      if (selectedStateId != null) {
        await prefs.setInt('state', selectedStateId!);
      }
      if (selectedDistrictId != null) {
        await prefs.setInt('district', selectedDistrictId!);
      }

      _showSuccessToast("Registration successful!");

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (_) => false,
          );
        }
      });
    } else {
      _showErrorToast("Registration failed. Please try again.");
    }
  }

  Widget _buildLocationSelectorButtons() {
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
                  selectedId: selectedCountryId,
                  color: AddressColors.senderPrimary,
                  onSelected: (country) async {
                    setState(() {
                      selectedCountry = country;
                      selectedState = null;
                      selectedDistrict = null;
                      states.clear();
                      districts.clear();
                    });

                    if (selectedCountryId != null) {
                      await _fetchStates(
                        countryId: selectedCountryId!,
                        page: 1,
                        search: null,
                      );
                    }
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
                      : AddressColors.senderPrimary.withOpacity(0.3),
                  width: selectedCountry == null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: selectedCountry == null
                        ? Colors.red
                        : AddressColors.senderPrimary,
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
                                : AddressColors.textSecondary,
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
                                : AddressColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: selectedCountry == null
                        ? Colors.red
                        : AddressColors.senderPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (selectedCountry != null)
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
                        selectedId: selectedStateId,
                        countryId: selectedCountryId!,
                        color: AddressColors.senderPrimary,
                        onSelected: (state) async {
                          setState(() {
                            selectedState = state;
                            selectedDistrict = null;
                            districts.clear();
                          });

                          if (selectedStateId != null) {
                            await _fetchDistricts(
                              stateId: selectedStateId!,
                              page: 1,
                              search: null,
                            );
                          }
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
                        : AddressColors.senderPrimary.withOpacity(0.3),
                    width: selectedState == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: selectedState == null
                          ? Colors.red
                          : AddressColors.senderPrimary,
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
                                  : AddressColors.textSecondary,
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
                                  : AddressColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: selectedState == null
                          ? Colors.red
                          : AddressColors.senderPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (selectedState != null)
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
                        selectedId: selectedDistrictId,
                        stateId: selectedStateId!,
                        color: ColorConstants.red,
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
                        : AddressColors.senderPrimary.withOpacity(0.3),
                    width: selectedDistrict == null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: selectedDistrict == null
                          ? Colors.red
                          : AddressColors.senderPrimary,
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
                                  : AddressColors.textSecondary,
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
                                  : AddressColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: selectedDistrict == null
                          ? Colors.red
                          : AddressColors.senderPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Terms & Conditions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please read and accept the following terms before registering your shop. These ensure smooth operations, accountability, and secure transactions within the platform.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 15),

              /// 1️⃣ Parcel Responsibility
              _modernCheckbox(
                value: parcelResponsibilityAccepted,
                onChanged: (val) {
                  setState(() => parcelResponsibilityAccepted = val!);
                },
                title: "Parcel Responsibility",
                subtitle:
                    "I agree to responsibly handle all parcels assigned to my shop, ensuring proper storage, safety, and timely handover to delivery partners without negligence.",
              ),

              const SizedBox(height: 10),

              /// 2️⃣ Damage / Loss
              _modernCheckbox(
                value: damageLossAccepted,
                onChanged: (val) {
                  setState(() => damageLossAccepted = val!);
                },
                title: "Damage / Loss Policy",
                subtitle:
                    "I understand that I may be held accountable for any damage, loss, or mishandling of parcels while they are under my supervision at the shop.",
              ),

              const SizedBox(height: 10),

              /// 3️⃣ Payout Terms
              _modernCheckbox(
                value: payoutTermsAccepted,
                onChanged: (val) {
                  setState(() => payoutTermsAccepted = val!);
                },
                title: "Payout & Earnings",
                subtitle:
                    "I agree to the platform's payout structure, commission rules, and settlement timelines, and acknowledge that payments will be processed accordingly.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.red : Colors.grey.shade300,
          width: value ? 1.5 : 1,
        ),
        boxShadow: [
          if (value)
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: value,
              activeColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.grey,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            const Text(
                              "Welcome To QDEL!",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  "+91 - ",
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  widget.phone,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 15),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "change",
                                    style: TextStyle(
                                      color: ColorConstants.deeporange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _firstName,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                ),
                                hintText: "First Name *",
                                hintStyle: const TextStyle(color: Colors.grey),
                                fillColor: ColorConstants.white,

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 1,
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 2,
                                  ),
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _lastName,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                ),
                                hintText: "Last Name *",
                                hintStyle: const TextStyle(color: Colors.grey),
                                fillColor: ColorConstants.white,

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 1,
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 2,
                                  ),
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _email,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.black,
                                ),
                                hintText: "Email *",
                                hintStyle: const TextStyle(color: Colors.grey),
                                fillColor: ColorConstants.white,

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 1,
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: ColorConstants.red,
                                    width: 2,
                                  ),
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: ColorConstants.red,
                                  width: 1,
                                ),
                                color: ColorConstants.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 15),
                                  const Text(
                                    "Select your User Type ",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: ColorConstants.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Radio(
                                            activeColor: ColorConstants.black,
                                            value: 'client',
                                            groupValue: _customertype,
                                            onChanged: (value) {
                                              setState(() {
                                                _customertype = value!;
                                              });
                                            },
                                          ),
                                          const Text(
                                            'Client',
                                            style: TextStyle(
                                              fontSize: 18,

                                              color: ColorConstants.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Radio(
                                            activeColor: ColorConstants.black,
                                            value: 'carrier',
                                            groupValue: _customertype,
                                            onChanged: (value) {
                                              setState(() {
                                                _customertype = value!;
                                              });
                                            },
                                          ),
                                          const Text(
                                            'Carrier',
                                            style: TextStyle(
                                              fontSize: 18,

                                              color: ColorConstants.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Radio(
                                            activeColor: ColorConstants.black,
                                            value: 'shop',
                                            groupValue: _customertype,
                                            onChanged: (value) {
                                              setState(() {
                                                _customertype = value!;
                                              });
                                            },
                                          ),
                                          const Text(
                                            'Shop Hub',
                                            style: TextStyle(
                                              fontSize: 18,

                                              color: ColorConstants.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildLocationSelectorButtons(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      (parcelResponsibilityAccepted &&
                                          damageLossAccepted &&
                                          payoutTermsAccepted)
                                      ? register
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.red,
                                    minimumSize: const Size(120, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
