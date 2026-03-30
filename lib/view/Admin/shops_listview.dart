import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'dart:async';

import 'package:projectqdel/view/Admin/shop_details.dart';

enum ShopTab { approved, pending, rejected }

class ShopApprovalScreen extends StatefulWidget {
  const ShopApprovalScreen({super.key});

  @override
  State<ShopApprovalScreen> createState() => _ShopApprovalScreenState();
}

class _ShopApprovalScreenState extends State<ShopApprovalScreen> {
  final ApiService apiService = ApiService();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  ShopTab currentTab = ShopTab.approved;

  List<Map<String, dynamic>> shops = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;

  bool loading = true;
  bool isLoadingMore = false;
  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops({int page = 1, bool isLoadMore = false}) async {
    setState(() {
      if (isLoadMore) {
        isLoadingMore = true;
      } else {
        loading = true;
        currentPage = page;
      }
    });

    String status;
    switch (currentTab) {
      case ShopTab.approved:
        status = "approved";
        break;
      case ShopTab.pending:
        status = "pending";
        break;
      case ShopTab.rejected:
        status = "rejected";
        break;
    }

    try {
      final result = await apiService.getShopsByStatus(
        status: status,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        page: page,
      );

      if (mounted) {
        setState(() {
          shops = List<Map<String, dynamic>>.from(result['shops']);
          print("-------$shops-----------");
          hasNextPage = result['hasNext'] as bool;
          hasPreviousPage = result['hasPrevious'] as bool;
          totalPages = result['totalPages'] as int;
          currentPage = result['currentPage'] as int;
          totalCount = result['count'] as int;
          loading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      logger.e("Error in fetchShops: $e");
      if (mounted) {
        setState(() {
          loading = false;
          isLoadingMore = false;
          shops = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load shops: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void loadNextPage() {
    if (hasNextPage && !isLoadingMore) {
      fetchShops(page: currentPage + 1, isLoadMore: false);
    }
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoadingMore) {
      fetchShops(page: currentPage - 1, isLoadMore: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: LiquidPullToRefresh(
        onRefresh: () => fetchShops(page: 1),
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 80,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _tabs()),

            if (!loading && shops.isNotEmpty)
              SliverToBoxAdapter(child: _paginationInfo()),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: loading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : shops.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No ${currentTab.toString().split('.').last} shops found",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => searchQuery = "");
                                  fetchShops(page: 1);
                                },
                                child: const Text("Clear Search"),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final shop = shops[i];
                        return _unifiedShopCard(shop);
                      }, childCount: shops.length),
                    ),
            ),

            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            if (!loading &&
                shops.isNotEmpty &&
                (hasNextPage || hasPreviousPage))
              SliverToBoxAdapter(child: _paginationControls()),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 50, bottom: 16),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: ColorConstants.black),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
          _debounceSearch();
        },
        decoration: InputDecoration(
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = "");
                    fetchShops(page: 1);
                  },
                )
              : null,
          hintText: "Search shop name...",
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
    );
  }

  Widget _paginationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${shops.length} of $totalCount shops",
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: ColorConstants.red,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorConstants.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Page $currentPage of $totalPages",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorConstants.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationControls() {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 40, right: 40),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationArrowButton(
            icon: Icons.chevron_left,
            onPressed: hasPreviousPage ? loadPreviousPage : null,
            enabled: hasPreviousPage,
          ),

          const SizedBox(width: 25),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$currentPage of $totalPages",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorConstants.red,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 25),

          _paginationArrowButton(
            icon: Icons.chevron_right,
            onPressed: hasNextPage ? loadNextPage : null,
            enabled: hasNextPage,
          ),
        ],
      ),
    );
  }

  Widget _paginationArrowButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          color: enabled ? ColorConstants.red : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: ColorConstants.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      fetchShops(page: 1);
    });
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _tab("APPROVED", ShopTab.approved),
            _tab("PENDING", ShopTab.pending),
            _tab("REJECTED", ShopTab.rejected),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, ShopTab tab) {
    final active = currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => currentTab = tab);
          fetchShops(page: 1);
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? ColorConstants.red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _unifiedShopCard(Map<String, dynamic> shop) {
    final status = (shop['shop_approval_status'] ?? "pending").toLowerCase();

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopDetailScreen(shopId: shop['id']),
          ),
        );

        if (result != null) {
          fetchShops(page: currentPage); // refresh if needed
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorConstants.grey),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(.15),
              child: const Icon(Icons.store),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (shop['shop_name'] ?? "SHOP").toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${shop['first_name']} ${shop['last_name']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "${shop['phone']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: status == "approved"
                          ? Colors.green.withOpacity(.2)
                          : status == "rejected"
                          ? Colors.red.withOpacity(.2)
                          : Colors.orange.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == "approved"
                            ? Colors.green
                            : status == "rejected"
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Action buttons based on current tab
            if (currentTab == ShopTab.approved)
              _actionButton(
                label: "REJECT",
                color: Colors.red,
                onPressed: () => _openStatusModal(shop, status),
              )
            else if (currentTab == ShopTab.pending)
              _actionButton(
                label: "APPROVE",
                color: Colors.green,
                onPressed: () => _openStatusModal(shop, status),
              )
            else if (currentTab == ShopTab.rejected)
              _actionButton(
                label: "APPROVE",
                color: Colors.green,
                onPressed: () => _openStatusModal(shop, status),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openStatusModal(Map<String, dynamic> shop, String initialStatus) {
    String selectedStatus = initialStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Update Shop Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _statusOption(
                    title: "Approve Shop",
                    subtitle: "Allow shop to operate",
                    selected: selectedStatus == "approved",
                    color: Colors.green,
                    onTap: () =>
                        setModalState(() => selectedStatus = "approved"),
                  ),
                  const SizedBox(height: 12),

                  _statusOption(
                    title: "Reject Shop",
                    subtitle: "Block this shop",
                    selected: selectedStatus == "rejected",
                    color: Colors.red,
                    onTap: () =>
                        setModalState(() => selectedStatus = "rejected"),
                  ),
                  const SizedBox(height: 12),

                  _statusOption(
                    title: "Set as Pending",
                    subtitle: "Move back to pending review",
                    selected: selectedStatus == "pending",
                    color: Colors.orange,
                    onTap: () =>
                        setModalState(() => selectedStatus = "pending"),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      final success = await apiService.updateShopStatus(
                        shopId: shop['id'],
                        status: selectedStatus,
                      );

                      if (!success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to update shop status"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      await fetchShops(page: currentPage);

                      if (mounted) {
                        String message;
                        Color color;
                        switch (selectedStatus) {
                          case "approved":
                            message = "Shop approved successfully";
                            color = Colors.green;
                            break;
                          case "rejected":
                            message = "Shop rejected successfully";
                            color = Colors.red;
                            break;
                          default:
                            message = "Shop status updated successfully";
                            color = Colors.orange;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: color,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Confirm Changes",
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorConstants.white,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: ColorConstants.white),
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

  Widget _statusOption({
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.15) : Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
