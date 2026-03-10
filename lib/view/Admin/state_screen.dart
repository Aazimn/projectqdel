import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_states.dart';
import 'package:projectqdel/view/Admin/district_screen.dart';
import 'package:projectqdel/view/Admin/update_state.dart';

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
  TextEditingController statectl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();
  ApiService apiService = ApiService();

  List<dynamic> allStates = [];
  List<dynamic> filteredStates = [];
  // Store all states from all pages for searching
  List<dynamic> _allStatesCache = [];

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = true;
  final int _itemsPerPage = 3; // Adjust based on your backend

  // Loading states
  bool _isLoadingPrevious = false;
  bool _isLoadingNext = false;
  bool _isSearching = false;
  bool isLoading = true;
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    loadStates();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  Future<void> loadStates({int page = 1, bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        allStates.clear();
        filteredStates.clear();
      });
    }

    try {
      // Backend already filters by country via getStates(countryId: ...)
      final data = await apiService.getStatesbycountry(
        countryId: widget.countryId,
        page: page,
      );

      setState(() {
        if (isLoadMore) {
          allStates.addAll(data);
          filteredStates.addAll(data);
        } else {
          allStates = data;
          filteredStates = data;
        }

        // Store in cache for search (all data fetched so far)
        _allStatesCache.addAll(data);

        // Check if we have more pages based on backend page size
        if (data.isNotEmpty) {
          _hasMorePages = data.length == _itemsPerPage;

          // Calculate total pages (approximate, using page size)
          if (data.length < _itemsPerPage) {
            _totalPages = page;
          } else {
            _totalPages = page + 1;
          }
        } else {
          _hasMorePages = false;
          if (page > 1) {
            _totalPages = page - 1;
          }
        }

        _currentPage = page;

        isLoading = false;
        _isLoadingPrevious = false;
        _isLoadingNext = false;
      });

      print(
        'State Page: $_currentPage, Data Length: ${data.length}, HasMore: $_hasMorePages',
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        _isLoadingPrevious = false;
        _isLoadingNext = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading states: $e")));
    }
  }

  // Method to load all pages for search
  Future<void> _loadAllPagesForSearch(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Clear cache before loading all pages
      _allStatesCache.clear();

      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        // Each call already returns only states for this country
        final data = await apiService.getStatesbycountry(
          countryId: widget.countryId,
          page: page,
        );

        _allStatesCache.addAll(data);

        hasMore = data.length == _itemsPerPage;
        page++;
      }

      _performSearch(query);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading all states: $e")));
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _searchStates(String query) {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      setState(() {
        filteredStates = List.from(allStates);
        _isSearching = false;
      });
      return;
    }

    if (_allStatesCache.length >= _totalPages * _itemsPerPage) {
      _performSearch(query);
    } else {
      _loadAllPagesForSearch(query);
    }
  }

  void _performSearch(String query) {
    final results = _allStatesCache.where((state) {
      final name = state['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStates = results;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
      allStates.clear();
      filteredStates.clear();
      _allStatesCache.clear();
      _currentSearchQuery = '';
      searchCtl.clear();
    });
    await loadStates(page: 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages) return;

    setState(() {
      _isLoadingNext = true;
    });

    await loadStates(page: _currentPage + 1, isLoadMore: false);
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1) return;

    setState(() {
      _isLoadingPrevious = true;
    });

    await loadStates(page: _currentPage - 1, isLoadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  setState(() {
                    _currentPage = 1;
                    _hasMorePages = true;
                    allStates.clear();
                    filteredStates.clear();
                    _allStatesCache.clear();
                    _currentSearchQuery = '';
                    searchCtl.clear();
                  });
                  await loadStates(page: 1);
                }
              },
              child: Icon(Icons.add, color: Colors.white),
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
            child: isLoading || _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.red,
                      ),
                    ),
                  )
                : filteredStates.isEmpty
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
                    itemCount: filteredStates.length,
                    itemBuilder: (context, index) {
                      final state = filteredStates[index];
                      return stateCard(state);
                    },
                  ),
          ),

          if (!_isSearching && filteredStates.isNotEmpty)
            _buildPaginationControls(),

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
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
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
                            color: ColorConstants.black,
                          ),
                        ),
                        Text(
                          "Country: ${widget.countryName}",
                          style: TextStyle(
                            fontSize: 13,
                            color: ColorConstants.black,
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
                      widget.countryName,
                      style: TextStyle(
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
                          setState(() {
                            _currentPage = 1;
                            _hasMorePages = true;
                            allStates.clear();
                            filteredStates.clear();
                            _allStatesCache.clear();
                            _currentSearchQuery = '';
                            searchCtl.clear();
                          });
                          await loadStates(page: 1);
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
                        final confirm = await _confirmDelete(context);

                        if (confirm == true) {
                          await apiService.deleteState(stateId: state["id"]);
                          setState(() {
                            _currentPage = 1;
                            _hasMorePages = true;
                            allStates.clear();
                            filteredStates.clear();
                            _allStatesCache.clear();
                            _currentSearchQuery = '';
                            searchCtl.clear();
                          });
                          await loadStates(page: 1);
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
      ),
    );
  }
}
