import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_district.dart';
import 'package:projectqdel/view/Admin/update_district.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DistrictScreen extends StatefulWidget {
  final int stateId;
  final String stateName;
  const DistrictScreen({
    super.key,
    required this.stateId,
    required this.stateName,
  });

  @override
  State<DistrictScreen> createState() => _DistrictScreenState();
}

class _DistrictScreenState extends State<DistrictScreen> {
  TextEditingController searchCtl = TextEditingController();
  ApiService apiService = ApiService();

  List<dynamic> _districts = [];
  List<dynamic> _allDistricts = [];
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

  // Grid configuration
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
    await fetchAllDistricts();
  }

  Future<void> fetchAllDistricts() async {
    print('🚀 FETCH ALL DISTRICTS');

    setState(() {
      isLoading = true;
    });

    try {
      final firstPageData = await getDistrictsByState(page: 1, search: null);

      if (firstPageData.isEmpty) {
        setState(() {
          _districts = [];
          _allDistricts = [];
          _totalItems = 0;
          _totalPages = 1;
          _hasMorePages = false;
          isLoading = false;
        });
        return;
      }

      if (firstPageData.length < _itemsPerPage) {
        setState(() {
          _allDistricts = firstPageData;
          _totalItems = firstPageData.length;
          _totalPages = 1;
          _hasMorePages = false;
          _districts = firstPageData;
          isLoading = false;
        });
        return;
      }

      List<dynamic> allData = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final pageData = await getDistrictsByState(page: page, search: null);
        if (pageData.isNotEmpty) {
          allData.addAll(pageData);
          hasMore = pageData.length == _itemsPerPage;
          page++;
        } else {
          hasMore = false;
        }
      }

      setState(() {
        _allDistricts = allData;
        _totalItems = allData.length;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _hasMorePages = _totalPages > 1;

        _loadPage(1);
        isLoading = false;
      });

      print(
        '✅ ALL DISTRICTS LOADED - Total: $_totalItems, Pages: $_totalPages',
      );
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading districts: $e")));
    }
  }

  void _loadPage(int page) {
    setState(() {
      _currentPage = page;

      int startIndex = (page - 1) * _itemsPerPage;
      int endIndex = startIndex + _itemsPerPage;

      if (startIndex < _allDistricts.length) {
        if (endIndex > _allDistricts.length) {
          endIndex = _allDistricts.length;
        }

        _districts = _allDistricts.sublist(startIndex, endIndex);
        _hasMorePages = page < _totalPages;
      } else {
        _districts = [];
        _hasMorePages = false;
      }
    });
  }

  Future<List<dynamic>> getDistrictsByState({
    required int page,
    String? search,
  }) async {
    String urlString =
        "${apiService.baseurl}/api/qdel/districts/by/state/${widget.stateId}/?page=$page";
    if (search != null && search.isNotEmpty) {
      urlString += "&search=$search";
    }

    final url = Uri.parse(urlString);

    print('🌐 FETCHING DISTRICTS FROM: $url');

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    print("📊 DISTRICTS STATUS: ${response.statusCode}");
    print("📦 DISTRICTS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map<String, dynamic>) {
        final results = decoded['results'];
        if (results is List) return results;
        final data = decoded['data'];
        if (data is List) return data;
        return const <dynamic>[];
      }
      return const <dynamic>[];
    } else {
      throw Exception("Failed to load districts: ${response.statusCode}");
    }
  }

  void _searchDistricts(String query) {
    print('🔍 SEARCH - Query: "$query"');

    setState(() {
      _currentSearchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      _loadPage(_currentPage);
    } else {
      final allFiltered = _allDistricts.where((district) {
        final name = district['name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      setState(() {
        _districts = allFiltered;
      });
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
    await fetchAllDistricts();
  }

  Future<void> _goToNextPage() async {
    if (_isLoadingNext || !_hasMorePages || _isSearching) return;

    setState(() {
      _isLoadingNext = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _loadPage(_currentPage + 1);

    setState(() {
      _isLoadingNext = false;
    });
  }

  Future<void> _goToPreviousPage() async {
    if (_isLoadingPrevious || _currentPage <= 1 || _isSearching) return;

    setState(() {
      _isLoadingPrevious = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _loadPage(_currentPage - 1);

    setState(() {
      _isLoadingPrevious = false;
    });
  }

  Future<void> _deleteDistrict(int districtId) async {
    try {
      setState(() => isLoading = true);

      final success = await apiService.deleteDistrict(districtId: districtId);

      if (success) {
        print('✅ Delete successful');
        _allDistricts.removeWhere((d) => d['id'] == districtId);
        _totalItems = _allDistricts.length;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;

        if (_isSearching) {
          _searchDistricts(_currentSearchQuery);
        } else {
          _loadPage(_currentPage);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('District deleted successfully'),
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
            content: Text('Error deleting district: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: Stack(
        children: [
          LiquidPullToRefresh(
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
                      // State indicator
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
                              Icons.location_city,
                              color: ColorConstants.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.stateName,
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

                      // Search field
                      TextField(
                        controller: searchCtl,
                        onChanged: _searchDistricts,
                        decoration: InputDecoration(
                          hintText: "Search districts...",
                          hintStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
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
                      : _districts.isEmpty
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
                                    ? "No districts match '$_currentSearchQuery'"
                                    : "No districts found in ${widget.stateName}",
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
                          itemCount: _districts.length,
                          itemBuilder: (context, index) {
                            final district = _districts[index];
                            return districtGridCard(district);
                          },
                        ),
                ),

                if (!_isSearching && _districts.isNotEmpty && _totalPages > 1)
                  _buildPaginationControls(),

                const SizedBox(height: 10),
              ],
            ),
          ),

          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConstants.red,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDistrictScreen(
                      stateId: widget.stateId,
                      stateName: widget.stateName,
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
              onPressed: _currentPage < _totalPages ? _goToNextPage : null,
              isLoading: _isLoadingNext,
              icon: Icons.arrow_forward,
              label: 'Next',
              isEnabled: _currentPage < _totalPages,
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
            "Delete District",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this district?",
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

  Widget districtGridCard(Map district) {
    final districtName = district['name']?.toString() ?? 'Unknown';
    final districtId = district['id'];

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
                        Icons.location_city,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      districtName.length > 12
                          ? '${districtName.substring(0, 10)}...'
                          : districtName,
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
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 10, color: Colors.black),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.stateName.length > 10
                            ? '${widget.stateName.substring(0, 8)}...'
                            : widget.stateName,
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
                            builder: (_) => UpdateDistrictScreen(
                              districtId: districtId,
                              districtName: districtName,
                              stateId: widget.stateId,
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
                          await _deleteDistrict(districtId);
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
