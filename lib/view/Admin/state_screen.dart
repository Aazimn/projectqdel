import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_states.dart';
import 'package:projectqdel/view/Admin/district_screen.dart';
import 'package:projectqdel/view/Admin/update_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StateScreen extends StatefulWidget {
  final int countryId;
  final String countryName;
  const StateScreen({
    super.key,
    required this.countryId,
    required this.countryName,
  });

  @override
  State<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {
  TextEditingController searchCtl = TextEditingController();
  ApiService apiService = ApiService();

  List<dynamic> _states = []; // Current page states
  List<dynamic> _allStatesCache = []; // Cache for search

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMorePages = true;
  final int _itemsPerPage = 3; // Based on your backend page size

  bool _isLoadingPrevious = false;
  bool _isLoadingNext = false;
  bool isLoading = true;
  bool _isSearching = false;
  String _currentSearchQuery = '';

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
    await fetchStates(page: 1);
  }

  Future<void> fetchStates({required int page}) async {
    print(
      '🚀 FETCH STATES - Requested page: $page, Current page: $_currentPage',
    );

    setState(() {
      if (page > _currentPage) {
        _isLoadingNext = true;
      } else if (page < _currentPage) {
        _isLoadingPrevious = true;
      } else {
        isLoading = true;
      }
    });

    try {
      final responseData = await getStatesByCountry(page: page);

      // Extract data from paginated response
      final List<dynamic> data = responseData['results'] ?? [];
      final int totalCount = responseData['count'] ?? 0;
      final bool hasNext = responseData['next'] != null;

      print(
        '📥 RECEIVED DATA - Page $page: ${data.length} items, Total: $totalCount, HasNext: $hasNext',
      );

      setState(() {
        _states = data;
        _currentPage = page;
        _totalItems = totalCount;
        _hasMorePages = hasNext;

        // Calculate total pages
        _totalPages = (totalCount / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;

        isLoading = false;
        _isLoadingNext = false;
        _isLoadingPrevious = false;
      });

      print(
        '✅ STATE UPDATED - Page: $_currentPage, Items: ${_states.length}, Total: $_totalItems, HasMore: $_hasMorePages, TotalPages: $_totalPages',
      );
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        isLoading = false;
        _isLoadingNext = false;
        _isLoadingPrevious = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading states: $e")));
    }
  }

  Future<Map<String, dynamic>> getStatesByCountry({required int page}) async {
    final url = Uri.parse(
      "${apiService.baseurl}/api/qdel/states/by/country/${widget.countryId}/?page=$page",
    );

    print('🌐 FETCHING STATES PAGE $page FROM: $url');

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    print("📊 STATES STATUS: ${response.statusCode}");
    print("📦 STATES BODY: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print(
        "📋 GOT ${jsonResponse['results']?.length ?? 0} STATES FROM PAGE $page",
      );
      print("📋 TOTAL COUNT: ${jsonResponse['count']}");
      print("📋 NEXT PAGE: ${jsonResponse['next']}");
      return jsonResponse;
    } else {
      throw Exception("Failed to load states: ${response.statusCode}");
    }
  }

  Future<void> _loadAllPagesForSearch(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      _allStatesCache.clear();

      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final responseData = await getStatesByCountry(page: page);
        final List<dynamic> data = responseData['results'] ?? [];

        if (data.isNotEmpty) {
          _allStatesCache.addAll(data);
          hasMore = responseData['next'] != null;
          page++;
        } else {
          hasMore = false;
        }
      }

      _performSearch(query);
    } catch (e) {
      print('Error loading all states for search: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _searchStates(String query) {
    setState(() {
      _currentSearchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      fetchStates(page: 1); // Reload first page
      return;
    }

    _loadAllPagesForSearch(query);
  }

  void _performSearch(String query) {
    final results = _allStatesCache.where((state) {
      final name = state['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _states = results; // Show search results
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _currentSearchQuery = '';
      _isSearching = false;
      searchCtl.clear();
      _allStatesCache.clear();
      isLoading = true;
    });
    await fetchStates(page: 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages || _isSearching) return;

    print(
      '👉 NEXT CLICKED - Current page: $_currentPage, HasMore: $_hasMorePages',
    );
    await fetchStates(page: _currentPage + 1);
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1 || _isSearching) return;

    print('👈 PREV CLICKED - Current page: $_currentPage');
    await fetchStates(page: _currentPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.bg,
      body: Stack(
        children: [
          _stateView(),
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConstants.red,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStateScreen(
                      countryId: widget.countryId,
                      countryName: widget.countryName,
                    ),
                  ),
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

  Widget _stateView() {
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
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.public,
                        color: ColorConstants.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.countryName,
                        style: const TextStyle(
                          color: ColorConstants.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtl,
                  onChanged: _searchStates,
                  decoration: InputDecoration(
                    hintText: "Search states...",
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: ColorConstants.red,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
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
                : _states.isEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentSearchQuery.isNotEmpty
                              ? "No states match '$_currentSearchQuery'"
                              : "No states found in ${widget.countryName}",
                          style: const TextStyle(
                            color: ColorConstants.black,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _states.length,
                    itemBuilder: (context, index) {
                      final state = _states[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: stateCard(state),
                      );
                    },
                  ),
          ),

          // Always show pagination when not searching and we have items
          if (!_isSearching && _states.isNotEmpty) _buildPaginationControls(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        minimumSize: const Size(double.infinity, 45),
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
            "Delete State",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this state?",
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

  Widget stateCard(Map state) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DistrictScreen(stateId: state['id'], stateName: state['name']),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state['name'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.bgred,
                        ),
                      ),
                      Text(
                        "Country: ${widget.countryName}",
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConstants.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey, height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateStateScreen(
                            stateId: state['id'],
                            stateName: state['name'],
                            countryId: widget.countryId,
                          ),
                        ),
                      );

                      if (result == true) {
                        _onRefresh();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Update"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.green,
                      side: const BorderSide(color: ColorConstants.green),
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
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) {
                        try {
                          // Show loading indicator
                          setState(() {
                            isLoading = true;
                          });

                          // Call delete API
                          final success = await apiService.deleteState(
                            stateId: state["id"],
                          );

                          if (success) {
                            print(
                              '✅ Delete successful, refreshing page $_currentPage',
                            );

                            // Refresh the current page data
                            await fetchStates(page: _currentPage);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('State deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Delete error: $e');
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting state: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
