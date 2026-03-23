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
  TextEditingController searchCtl = TextEditingController();
  final ApiService apiService = ApiService();

  List<dynamic> _countries = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMorePages = true;
  final int _itemsPerPage = 10;

  bool _isLoadingPrevious = false;
  bool _isLoadingNext = false;
  bool isLoading = true;
  bool _isSearching = false;
  String _currentSearchQuery = '';

  final int _crossAxisCount = 2;
  final double _cardAspectRatio = 1.1;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    await ApiService.loadSession();
    await fetchCountries(page: 1);
  }

  Future<void> fetchCountries({required int page, String? searchQuery}) async {
    print(
      '🚀 FETCH COUNTRIES - Page: $page, Search: "$searchQuery", Current Page: $_currentPage',
    );

    setState(() {
      if (!_isSearching) {
        if (page > _currentPage) {
          _isLoadingNext = true;
        } else if (page < _currentPage) {
          _isLoadingPrevious = true;
        } else {
          isLoading = true;
        }
      }
    });

    try {
      final response = await apiService.getCountries(
        page: page,
        search: searchQuery,
      );

      if (searchQuery != null && searchQuery.isNotEmpty) {
        List<dynamic> data = [];
        int totalCount = 0;

        if (response is Map) {
          data = response['data'] ?? response['results'] ?? [];
          totalCount = response['count'] ?? data.length;
        } else if (response is List) {
          data = response;
          totalCount = data.length;
        }

        print(
          '📥 SEARCH RESULTS - Found: ${data.length} items, Total: $totalCount',
        );

        setState(() {
          _countries = data;
          _totalItems = totalCount;
          _totalPages = 1;
          _hasMorePages = false;
          _isSearching = true;
          isLoading = false;
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });
      } else {
        List<dynamic> data = [];
        int totalCount = 0;
        bool hasNext = false;

        if (response is Map) {
          data = response['results'] ?? [];
          totalCount = response['count'] ?? 0;
          hasNext = response['next'] != null;
        } else if (response is List) {
          data = response;
          totalCount = data.length;
          hasNext = false;
        }

        print(
          '📥 PAGINATED RESULTS - Page $page: ${data.length} items, Total: $totalCount, HasNext: $hasNext',
        );

        setState(() {
          _countries = data;
          _currentPage = page;
          _totalItems = totalCount;
          _hasMorePages = hasNext;
          _totalPages = (totalCount / _itemsPerPage).ceil();
          if (_totalPages == 0) _totalPages = 1;
          _isSearching = false;
          isLoading = false;
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });
      }

      print(
        '✅ STATE UPDATED - Items: ${_countries.length}, Total: $_totalItems, HasMore: $_hasMorePages',
      );
    } catch (e) {
      print('❌ ERROR: $e');

      if (page > 1 && e.toString().contains('Invalid page')) {
        print('⚠️ Page $page is invalid, falling back to page 1');
        setState(() {
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });
        await fetchCountries(page: 1, searchQuery: searchQuery);
      } else {
        setState(() {
          isLoading = false;
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading countries: ${e.toString()}")),
          );
        }
      }
    }
  }

  void _searchCountries(String query) {
    print('🔍 SEARCH - Query: "$query"');

    setState(() {
      _currentSearchQuery = query;
      isLoading = true;
    });

    if (query.isEmpty) {
      fetchCountries(page: 1);
    } else {
      fetchCountries(page: 1, searchQuery: query);
    }
  }

  Future<void> _onRefresh() async {
    print('🔄 REFRESH');
    setState(() {
      _currentPage = 1;
      _currentSearchQuery = '';
      _isSearching = false;
      searchCtl.clear();
      isLoading = true;
    });
    await fetchCountries(page: 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages || _isSearching) return;
    print('👉 NEXT PAGE - Current: $_currentPage');
    await fetchCountries(page: _currentPage + 1);
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1 || _isSearching) return;
    print('👈 PREV PAGE - Current: $_currentPage');
    await fetchCountries(page: _currentPage - 1);
  }

  Future<void> _deleteCountry(int countryId) async {
    try {
      setState(() => isLoading = true);

      final success = await apiService.deleteCountry(countryId: countryId);

      if (success) {
        print('✅ Delete successful');
        int newTotalItems = _totalItems - 1;
        int newTotalPages = (newTotalItems / _itemsPerPage).ceil();
        if (newTotalPages == 0) newTotalPages = 1;
        int pageToFetch = _currentPage;
        if (_currentPage > newTotalPages) {
          pageToFetch = newTotalPages;
        }

        print(
          '📊 After delete - Total items: $newTotalItems, Pages: $newTotalPages, Fetching page: $pageToFetch',
        );

        if (_isSearching) {
          await fetchCountries(page: 1, searchQuery: _currentSearchQuery);
        } else {
          await fetchCountries(page: pageToFetch);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Country deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Delete error: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting country: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.bg,
      body: Stack(
        children: [
          _countryView(),
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConstants.red,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddCountryScreen()),
                );

                if (result == true) {
                  _onRefresh();
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryView() {
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
              onChanged: _searchCountries,
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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.red,
                      ),
                    ),
                  )
                : _countries.isEmpty
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
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: _cardAspectRatio,
                    ),
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return countryGridCard(country);
                    },
                  ),
          ),

          if (!_isSearching && _countries.isNotEmpty && _totalPages > 1)
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
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

  Widget countryGridCard(Map country) {
    final countryName = country['name']?.toString() ?? 'Unknown';
    final countryCode = country['code']?.toString() ?? '';
    final countryId = country['id'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StateScreen(countryId: countryId, countryName: countryName),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.2,
                          colors: [Colors.red, Colors.red.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          countryName.length > 12
                              ? '${countryName.substring(0, 10)}...'
                              : countryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 10, color: Colors.black),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          countryCode.isNotEmpty ? '+$countryCode' : 'NO CODE',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_city,
                        size: 10,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'States',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 8,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildGridActionButton(
                        icon: Icons.edit,
                        color: Colors.green,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpdateCountryScreen(
                                countryId: countryId,
                                name: countryName,
                                code: countryCode,
                              ),
                            ),
                          );

                          if (result == true) {
                            _onRefresh();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    Expanded(
                      child: _buildGridActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await _confirmDelete(context);
                          if (confirm == true) {
                            await _deleteCountry(countryId);
                          }
                        },
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

  Widget _buildGridActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}
