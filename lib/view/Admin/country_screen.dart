import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_country.dart';
import 'package:projectqdel/view/Admin/state_screen.dart';
import 'package:projectqdel/view/Admin/update_country.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  TextEditingController countryctl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();
  TextEditingController countryCodeCtl = TextEditingController();
  ApiService apiService = ApiService();
  List<dynamic> _allCountries = [];
  List<dynamic> _filteredCountries = [];
  List<dynamic> _allCountriesCache = [];

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = true;
  // ignore: unused_field
  bool _isLoadingMore = false;
  final int _itemsPerPage = 10;

  bool _isLoadingPrevious = false;
  bool _isLoadingNext = false;

  bool isLoading = true;
  bool _isSearching = false;
  String _currentSearchQuery = '';

  int? selectedCountryId;
  String? selectedCountryName;

  int? selectedStateId;
  String? selectedStateName;

  @override
  void initState() {
    super.initState();
    print('🟢 [INIT] CountryScreen initialized');
    loadData();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    print('📦 [LOAD] Loading data...');
    await ApiService.loadSession();
    await fetchCountries();
  }

  Future<void> fetchCountries({int page = 1, bool isLoadMore = false}) async {
    print(
      '🔍 [FETCH] Starting fetch - Page: $page, isLoadMore: $isLoadMore, Current Page: $_currentPage',
    );

    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        _allCountries.clear();
        _filteredCountries.clear();
      });
    }

    try {
      print('📡 [API] Calling getCountries with page: $page');
      final response = await apiService.getCountries(page: page);
      print('📦 [API] Response received - Type: ${response.runtimeType}');
      print('📦 [API] Response data: $response');

      List<dynamic> data;
      int totalCount = 0;
      bool hasNext = false;

      if (response is List) {
        data = response;
        totalCount = data.length;
        hasNext = false;
        print('📋 [API] Direct list response with ${data.length} items');
      } else if (response is Map) {
        // Paginated response
        data = response['results'] ?? [];
        totalCount = response['count'] ?? 0;
        hasNext = response['next'] != null;
        print(
          '📊 [API] Paginated response with ${data.length} items, total: $totalCount, hasNext: $hasNext',
        );
      } else {
        throw Exception('Unexpected response type: ${response.runtimeType}');
      }

      setState(() {
        if (isLoadMore) {
          _allCountries.addAll(data);
          _filteredCountries.addAll(data);
        } else {
          _allCountries = data;
          _filteredCountries = data;
        }

        _allCountriesCache.addAll(data);

        if (data.isNotEmpty) {
          _hasMorePages = hasNext;

          if (totalCount > 0) {
            _totalPages = (totalCount / _itemsPerPage).ceil();
            print(
              '📊 [PAGINATION] Total pages calculated: $_totalPages (total: $totalCount, per page: $_itemsPerPage)',
            );
          } else {
            if (!hasNext) {
              _totalPages = page;
              print(
                '📊 [PAGINATION] Last page detected - Total Pages: $_totalPages',
              );
            } else {
              _totalPages = page + 1;
              print(
                '📊 [PAGINATION] More pages available - Total Pages: $_totalPages',
              );
            }
          }
        } else {
          _hasMorePages = false;
          if (page > 1) {
            _totalPages = page - 1;
          }
          print(
            '📊 [PAGINATION] Empty response - HasMore: $_hasMorePages, Total Pages: $_totalPages',
          );
        }

        _currentPage = page;

        isLoading = false;
        _isLoadingMore = false;
        _isLoadingPrevious = false;
        _isLoadingNext = false;
      });
      print(
        '✅ [STATE] Updated - Page: $_currentPage, HasMore: $_hasMorePages, Data Length: ${data.length}, Total Pages: $_totalPages',
      );
    } catch (e, stackTrace) {
      print('❌ [ERROR] Exception: $e');
      print('❌ [ERROR] Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
        _isLoadingPrevious = false;
        _isLoadingNext = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading countries: $e")));
    }
  }

  Future<void> _loadAllPagesForSearch(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      _allCountriesCache.clear();
      print('🔍 [SEARCH] Loading search results for query: "$query"');
      final response = await apiService.getCountries(search: query);

      List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map) {
        data = response['results'] ?? [];
      } else {
        data = [];
      }

      print('🔍 [SEARCH] Received ${data.length} items');
      _allCountriesCache.addAll(data);
      _performSearch(query);
    } catch (e) {
      print('❌ [SEARCH] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading all countries: $e")),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _searchCountry(String query) {
    print('🔍 [SEARCH] Search query changed: "$query"');
    _currentSearchQuery = query;

    if (query.isEmpty) {
      print('🔍 [SEARCH] Query empty, resetting to all countries');
      setState(() {
        _filteredCountries = List.from(_allCountries);
        _isSearching = false;
      });
      return;
    }

    if (_allCountriesCache.length >= _totalPages * _itemsPerPage) {
      print(
        '🔍 [SEARCH] Using cached data - Cache size: ${_allCountriesCache.length}, Required: ${_totalPages * _itemsPerPage}',
      );
      _performSearch(query);
    } else {
      print('🔍 [SEARCH] Cache miss, loading all pages');
      _loadAllPagesForSearch(query);
    }
  }

  void _performSearch(String query) {
    print(
      '🔍 [SEARCH] Performing search on ${_allCountriesCache.length} items',
    );
    final results = _allCountriesCache.where((country) {
      final name = country['name'].toString().toLowerCase();
      final code = country['code']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) ||
          code.contains(query.toLowerCase());
    }).toList();

    print('🔍 [SEARCH] Found ${results.length} matches');
    setState(() {
      _filteredCountries = results;
    });
  }

  Future<void> _onRefresh() async {
    print('🔄 [REFRESH] Refreshing data');
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
      _allCountries.clear();
      _filteredCountries.clear();
      _allCountriesCache.clear();
      _currentSearchQuery = '';
      searchCtl.clear();
    });
    await fetchCountries(page: 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages) {
      print(
        '⛔ [NAV] Cannot go to next page - isLoadingNext: $_isLoadingNext, hasMorePages: $_hasMorePages',
      );
      return;
    }

    print('👉 [NAV] Going to next page: ${_currentPage + 1}');
    setState(() {
      _isLoadingNext = true;
    });

    await fetchCountries(page: _currentPage + 1);
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1) {
      print(
        '⛔ [NAV] Cannot go to previous page - isLoadingPrevious: $_isLoadingPrevious, currentPage: $_currentPage',
      );
      return;
    }

    print('👈 [NAV] Going to previous page: ${_currentPage - 1}');
    setState(() {
      _isLoadingPrevious = true;
    });

    await fetchCountries(page: _currentPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🎨 [BUILD] Building UI - Page: $_currentPage, TotalPages: $_totalPages, HasMore: $_hasMorePages, Items: ${_filteredCountries.length}',
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.bg,
      body: Stack(
        children: [
          _countryview(),
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConstants.red,
              onPressed: () async {
                print('➕ [FAB] Add button clicked');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddCountryScreen()),
                );

                if (result == true) {
                  print('➕ [FAB] Add successful, refreshing');
                  fetchCountries();
                  setState(() {
                    _allCountriesCache.clear();
                    _currentSearchQuery = '';
                    searchCtl.clear();
                  });
                }
              },
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryview() {
    return LiquidPullToRefresh(
      onRefresh: _onRefresh,
      color: ColorConstants.red,
      backgroundColor: Colors.white,
      height: 80,
      animSpeedFactor: 4.0,
      showChildOpacityTransition: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 50,
              bottom: 16,
            ),
            child: TextField(
              controller: searchCtl,
              onChanged: _searchCountry,
              decoration: InputDecoration(
                hintText: "Search country...",
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: ColorConstants.red,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading || _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.red,
                      ),
                    ),
                  )
                : _filteredCountries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentSearchQuery.isNotEmpty
                              ? "No countries match '$_currentSearchQuery'"
                              : "No countries found",
                          style: const TextStyle(
                            color: ColorConstants.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: countryCard(country),
                      );
                    },
                  ),
          ),

          if (!_isSearching &&
              _filteredCountries.isNotEmpty &&
              (_totalPages > 1 || _currentPage > 1 || _hasMorePages))
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    print(
      '🔢 [PAGINATION] Building pagination controls - Page $_currentPage of $_totalPages, HasMore: $_hasMorePages',
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildNavigationButton(
              onPressed: _currentPage > 1 ? _goToPreviousPage : null,
              isLoading: _isLoadingPrevious,
              icon: Icons.arrow_back,
              label: 'Prev',
              isEnabled: _currentPage > 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalPages > 1
                  ? 'Page $_currentPage of $_totalPages'
                  : 'Page $_currentPage',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ColorConstants.red,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: _buildNavigationButton(
              onPressed: _hasMorePages ? _goToNextPage : null,
              isLoading: _isLoadingNext,
              icon: Icons.arrow_forward,
              label: 'Next',
              isEnabled: _hasMorePages,
              isNext: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required IconData icon,
    required String label,
    required bool isEnabled,
    bool isNext = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? ColorConstants.red : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isEnabled ? 2 : 0,
        minimumSize: const Size(double.infinity, 25),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isNext) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isNext) ...[const SizedBox(width: 4), Icon(icon, size: 18)],
              ],
            ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Delete Country",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this country?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget countryCard(Map country) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        print(
          '👆 [CARD] Country tapped - ID: ${country['id']}, Name: ${country['name']}',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StateScreen(
              countryId: country['id'],
              countryName: country['name'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ColorConstants.bgred),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.public, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country['name'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.bgred,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+${country['code'] ?? ''}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      print(
                        '✏️ [UPDATE] Update button clicked for country ID: ${country['id']}',
                      );
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateCountryScreen(
                            countryId: country['id'],
                            name: country['name'],
                            code: country['code'],
                          ),
                        ),
                      );

                      if (result == true) {
                        print('✏️ [UPDATE] Update successful, refreshing');
                        fetchCountries();
                        setState(() {
                          _allCountriesCache.clear();
                          _currentSearchQuery = '';
                          searchCtl.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Update"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.green,
                      side: BorderSide(color: ColorConstants.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      print(
                        '🗑️ [DELETE] Delete button clicked for country ID: ${country['id']}',
                      );
                      final confirm = await _confirmDelete(context);

                      if (confirm == true) {
                        print('🗑️ [DELETE] Delete confirmed');
                        await apiService.deleteCountry(
                          countryId: country['id'],
                        );
                        print('🗑️ [DELETE] Delete API called, refreshing');
                        fetchCountries();
                        setState(() {
                          _allCountriesCache.clear();
                          _currentSearchQuery = '';
                          searchCtl.clear();
                        });
                      } else {
                        print('🗑️ [DELETE] Delete cancelled');
                      }
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
