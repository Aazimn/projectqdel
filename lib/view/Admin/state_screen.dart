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
  TextEditingController searchCtl = TextEditingController();
  final ApiService apiService = ApiService();

  List<dynamic> _states = [];
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
    await fetchStates(page: 1);
  }

  Future<void> fetchStates({required int page, String? searchQuery}) async {
    print(
      '🚀 FETCH STATES - Page: $page, Search: "$searchQuery", Current Page: $_currentPage',
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
      final response = await apiService.getStatesByCountry(
        countryId: widget.countryId,
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
          _states = data;
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
          _states = data;
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
        '✅ STATE UPDATED - Items: ${_states.length}, Total: $_totalItems, HasMore: $_hasMorePages',
      );
    } catch (e) {
      print('❌ ERROR: $e');
      if (page > 1 && e.toString().contains('Invalid page')) {
        print('⚠️ Page $page is invalid, falling back to page 1');
        setState(() {
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });
        await fetchStates(page: 1, searchQuery: searchQuery);
      } else {
        setState(() {
          isLoading = false;
          _isLoadingNext = false;
          _isLoadingPrevious = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading states: ${e.toString()}")),
          );
        }
      }
    }
  }

  void _searchStates(String query) {
    print('🔍 SEARCH - Query: "$query"');

    setState(() {
      _currentSearchQuery = query;
      isLoading = true;
    });

    if (query.isEmpty) {
      fetchStates(page: 1);
    } else {
      fetchStates(page: 1, searchQuery: query);
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
    await fetchStates(page: 1);
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages || _isSearching) return;
    print('👉 NEXT PAGE - Current: $_currentPage');
    await fetchStates(page: _currentPage + 1);
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1 || _isSearching) return;
    print('👈 PREV PAGE - Current: $_currentPage');
    await fetchStates(page: _currentPage - 1);
  }

  Future<void> _deleteState(int stateId) async {
    try {
      setState(() => isLoading = true);

      final success = await apiService.deleteState(stateId: stateId);

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
          await fetchStates(page: 1, searchQuery: _currentSearchQuery);
        } else {
          await fetchStates(page: pageToFetch);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('State deleted successfully'),
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
            content: Text('Error deleting state: $e'),
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
                : _states.isEmpty
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _cardAspectRatio,
                        ),
                        itemCount: _states.length,
                        itemBuilder: (context, index) {
                          final state = _states[index];
                          return stateGridCard(state);
                        },
                      ),
          ),

          if (!_isSearching && _states.isNotEmpty && _totalPages > 1)
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

  Widget stateGridCard(Map state) {
    final stateName = state['name']?.toString() ?? 'Unknown';
    final stateId = state['id'];

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
                builder: (_) => DistrictScreen(
                  stateId: stateId,
                  stateName: stateName,
                ),
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
                      width: 30,
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
                      child: const Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stateName.length > 12
                            ? '${stateName.substring(0, 10)}...'
                            : stateName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      Icon(Icons.public, size: 10, color: Colors.black),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.countryName.length > 10
                              ? '${widget.countryName.substring(0, 8)}...'
                              : widget.countryName,
                          style: TextStyle(
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
                      const Icon(Icons.location_city, size: 10, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'Districts',
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
                              builder: (_) => UpdateStateScreen(
                                stateId: stateId,
                                stateName: stateName,
                                countryId: widget.countryId,
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
                            await _deleteState(stateId);
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