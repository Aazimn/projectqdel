import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/complaint_bottomsheet.dart';
import 'package:projectqdel/view/Client/order_detailed.dart';
import 'package:projectqdel/view/Client/edit_order.dart';
import 'package:projectqdel/view/Client/order_tracking.dart';
import 'package:logger/logger.dart';

class MyOrdersScreen extends StatefulWidget {
  final int initialTab;

  const MyOrdersScreen({super.key, this.initialTab = 0});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final Logger logger = Logger();
  final ApiService apiService = ApiService();

  late int _selectedTab;
  static const int itemsPerPage = 10;

  List<dynamic> searchingOrders = [];
  int searchingCurrentPage = 1;
  int searchingTotalPages = 1;
  int searchingTotalCount = 0;
  bool isLoadingSearching = true;
  String searchingSearch = '';
  final TextEditingController searchingController = TextEditingController();
  Timer? _searchingDebounce;

  List<dynamic> ongoingOrders = [];
  int ongoingCurrentPage = 1;
  int ongoingTotalPages = 1;
  int ongoingTotalCount = 0;
  bool isLoadingOngoing = true;
  String ongoingSearch = '';
  final TextEditingController ongoingController = TextEditingController();
  Timer? _ongoingDebounce;

  List<dynamic> completedOrders = [];
  int completedCurrentPage = 1;
  int completedTotalPages = 1;
  int completedTotalCount = 0;
  bool isLoadingCompleted = true;
  String completedSearch = '';
  final TextEditingController completedController = TextEditingController();
  Timer? _completedDebounce;

  bool isLoadingPrev = false;
  bool isLoadingNext = false;

  List<dynamic> get _currentOrders {
    switch (_selectedTab) {
      case 0:
        return searchingOrders;
      case 1:
        return ongoingOrders;
      default:
        return completedOrders;
    }
  }

  int get _currentPage {
    switch (_selectedTab) {
      case 0:
        return searchingCurrentPage;
      case 1:
        return ongoingCurrentPage;
      default:
        return completedCurrentPage;
    }
  }

  int get _currentTotalPages {
    switch (_selectedTab) {
      case 0:
        return searchingTotalPages;
      case 1:
        return ongoingTotalPages;
      default:
        return completedTotalPages;
    }
  }

  int get _currentTotalCount {
    switch (_selectedTab) {
      case 0:
        return searchingTotalCount;
      case 1:
        return ongoingTotalCount;
      default:
        return completedTotalCount;
    }
  }

  bool get _isLoadingCurrent {
    switch (_selectedTab) {
      case 0:
        return isLoadingSearching;
      case 1:
        return isLoadingOngoing;
      default:
        return isLoadingCompleted;
    }
  }

  String get _currentSearch {
    switch (_selectedTab) {
      case 0:
        return searchingSearch;
      case 1:
        return ongoingSearch;
      default:
        return completedSearch;
    }
  }

  TextEditingController get _currentController {
    switch (_selectedTab) {
      case 0:
        return searchingController;
      case 1:
        return ongoingController;
      default:
        return completedController;
    }
  }

  String get _emptyMessage {
    switch (_selectedTab) {
      case 0:
        return 'No orders being searched';
      case 1:
        return 'No ongoing orders';
      default:
        return 'No completed orders';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
    _fetchSearching(page: 1);
    _fetchOngoing(page: 1);
    _fetchCompleted(page: 1);
  }

  @override
  void dispose() {
    _searchingDebounce?.cancel();
    _ongoingDebounce?.cancel();
    _completedDebounce?.cancel();
    searchingController.dispose();
    ongoingController.dispose();
    completedController.dispose();
    super.dispose();
  }

  Future<void> _fetchSearching({required int page, String? search}) async {
    setState(() => isLoadingSearching = true);
    try {
      final response = await apiService.getAcceptedOrders(
        page: page,
        search: (search != null && search.isNotEmpty) ? search : null,
        status: 'pending',
      );
      final (orders, totalCount, totalPages) = _parseResponse(response);
      setState(() {
        searchingOrders = orders;
        searchingTotalCount = totalCount;
        searchingTotalPages = totalPages;
        searchingCurrentPage = page;
        isLoadingSearching = false;
      });
    } catch (e) {
      logger.e('❌ Searching fetch error: $e');
      setState(() {
        searchingOrders = [];
        searchingTotalCount = 0;
        searchingTotalPages = 1;
        isLoadingSearching = false;
      });
    }
  }

  Future<void> _fetchOngoing({required int page, String? search}) async {
    setState(() => isLoadingOngoing = true);
    try {
      final response = await apiService.getAcceptedOrders(
        page: page,
        search: (search != null && search.isNotEmpty) ? search : null,
        status: 'active',
      );
      final (orders, totalCount, totalPages) = _parseResponse(response);
      setState(() {
        ongoingOrders = orders;
        ongoingTotalCount = totalCount;
        ongoingTotalPages = totalPages;
        ongoingCurrentPage = page;
        isLoadingOngoing = false;
      });
    } catch (e) {
      logger.e('❌ Ongoing fetch error: $e');
      setState(() {
        ongoingOrders = [];
        ongoingTotalCount = 0;
        ongoingTotalPages = 1;
        isLoadingOngoing = false;
      });
    }
  }

  Future<void> _fetchCompleted({required int page, String? search}) async {
    setState(() => isLoadingCompleted = true);
    try {
      final response = await apiService.getAcceptedOrders(
        page: page,
        search: (search != null && search.isNotEmpty) ? search : null,
        status: 'completed',
      );
      final (orders, totalCount, totalPages) = _parseResponse(response);
      setState(() {
        completedOrders = orders;
        completedTotalCount = totalCount;
        completedTotalPages = totalPages;
        completedCurrentPage = page;
        isLoadingCompleted = false;
      });
    } catch (e) {
      logger.e('❌ Completed fetch error: $e');
      setState(() {
        completedOrders = [];
        completedTotalCount = 0;
        completedTotalPages = 1;
        isLoadingCompleted = false;
      });
    }
  }

  (List<dynamic>, int, int) _parseResponse(dynamic response) {
    List<dynamic> orders = [];
    int totalCount = 0;
    if (response is Map) {
      orders = (response['data'] as List?) ?? [];
      final c = response['count'];
      if (c != null) totalCount = c is int ? c : (c as num).toInt();
    } else if (response is List) {
      orders = response;
      totalCount = response.length;
    }
    final totalPages = totalCount > 0 ? (totalCount / itemsPerPage).ceil() : 1;
    return (orders, totalCount, totalPages);
  }

  Future<void> _onRefresh() async {
    searchingController.clear();
    ongoingController.clear();
    completedController.clear();
    setState(() {
      searchingSearch = '';
      ongoingSearch = '';
      completedSearch = '';
      searchingCurrentPage = 1;
      ongoingCurrentPage = 1;
      completedCurrentPage = 1;
    });
    await Future.wait([
      _fetchSearching(page: 1),
      _fetchOngoing(page: 1),
      _fetchCompleted(page: 1),
    ]);
  }

  Future<void> _nextPage() async {
    if (isLoadingNext) return;
    setState(() => isLoadingNext = true);
    switch (_selectedTab) {
      case 0:
        if (searchingCurrentPage < searchingTotalPages) {
          await _fetchSearching(
            page: searchingCurrentPage + 1,
            search: searchingSearch,
          );
        }
        break;
      case 1:
        if (ongoingCurrentPage < ongoingTotalPages) {
          await _fetchOngoing(
            page: ongoingCurrentPage + 1,
            search: ongoingSearch,
          );
        }
        break;
      case 2:
        if (completedCurrentPage < completedTotalPages) {
          await _fetchCompleted(
            page: completedCurrentPage + 1,
            search: completedSearch,
          );
        }
        break;
    }
    setState(() => isLoadingNext = false);
  }

  Future<void> _prevPage() async {
    if (isLoadingPrev) return;
    setState(() => isLoadingPrev = true);
    switch (_selectedTab) {
      case 0:
        if (searchingCurrentPage > 1) {
          await _fetchSearching(
            page: searchingCurrentPage - 1,
            search: searchingSearch,
          );
        }
        break;
      case 1:
        if (ongoingCurrentPage > 1) {
          await _fetchOngoing(
            page: ongoingCurrentPage - 1,
            search: ongoingSearch,
          );
        }
        break;
      case 2:
        if (completedCurrentPage > 1) {
          await _fetchCompleted(
            page: completedCurrentPage - 1,
            search: completedSearch,
          );
        }
        break;
    }
    setState(() => isLoadingPrev = false);
  }

  void _onSearchChanged(String query) {
    switch (_selectedTab) {
      case 0:
        _searchingDebounce?.cancel();
        _searchingDebounce = Timer(const Duration(milliseconds: 500), () {
          setState(() => searchingSearch = query);
          _fetchSearching(page: 1, search: query);
        });
        break;
      case 1:
        _ongoingDebounce?.cancel();
        _ongoingDebounce = Timer(const Duration(milliseconds: 500), () {
          setState(() => ongoingSearch = query);
          _fetchOngoing(page: 1, search: query);
        });
        break;
      case 2:
        _completedDebounce?.cancel();
        _completedDebounce = Timer(const Duration(milliseconds: 500), () {
          setState(() => completedSearch = query);
          _fetchCompleted(page: 1, search: query);
        });
        break;
    }
  }

  void _clearSearch() {
    _currentController.clear();
    switch (_selectedTab) {
      case 0:
        setState(() => searchingSearch = '');
        _fetchSearching(page: 1);
        break;
      case 1:
        setState(() => ongoingSearch = '');
        _fetchOngoing(page: 1);
        break;
      case 2:
        setState(() => completedSearch = '');
        _fetchCompleted(page: 1);
        break;
    }
  }

  String resolveOrderState(Map<String, dynamic> order) {
    if (_selectedTab == 0) return 'searching';
    final shipment = order['shipment_status'];
    if (shipment == null) return 'unknown';
    return shipment['status']?.toString().toLowerCase() ?? 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final bool showPagination = _currentTotalPages > 1;

    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 8),
                ]),
              ),
            ),

            _isLoadingCurrent && _currentOrders.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.red,
                        ),
                      ),
                    ),
                  )
                : _currentOrders.isEmpty && !_isLoadingCurrent
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentSearch.isNotEmpty
                                ? "No orders matching '$_currentSearch'"
                                : _emptyMessage,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < _currentOrders.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _orderCardFromApi(_currentOrders[index]),
                            );
                          } else if (index == _currentOrders.length &&
                              showPagination) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 20,
                              ),
                              child: _buildPaginationInList(),
                            );
                          }
                          return null;
                        },
                        childCount:
                            _currentOrders.length + (showPagination ? 1 : 0),
                      ),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorConstants.red,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabItem('Searching', 0),
          _tabItem('On-going', 1),
          _tabItem('Completed', 2),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (_selectedTab != index) {
            setState(() => _selectedTab = index);
            switch (index) {
              case 0: // Searching
                await _fetchSearching(page: 1, search: searchingSearch);
                break;
              case 1: // On-going
                await _fetchOngoing(page: 1, search: ongoingSearch);
                break;
              case 2: // Completed
                await _fetchCompleted(page: 1, search: completedSearch);
                break;
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _currentController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search orders by ID, product or status...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _currentSearch.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: _clearSearch,
              )
            : null,
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
    );
  }

  Widget _buildPaginationInList() {
    final bool hasNext = _currentPage < _currentTotalPages;
    final bool hasPrev = _currentPage > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage of $_currentTotalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ColorConstants.red,
                fontSize: 14,
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _buildNavButton(
                  onPressed: hasPrev ? _prevPage : null,
                  isLoading: isLoadingPrev,
                  icon: Icons.arrow_back,
                  label: 'Previous',
                  isEnabled: hasPrev,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNavButton(
                  onPressed: hasNext ? _nextPage : null,
                  isLoading: isLoadingNext,
                  icon: Icons.arrow_forward,
                  label: 'Next',
                  isEnabled: hasNext,
                  isNext: true,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Total $_currentTotalCount orders',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required IconData icon,
    required String label,
    required bool isEnabled,
    bool isNext = false,
  }) {
    return ElevatedButton(
      onPressed: (isLoading || !isEnabled) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? ColorConstants.red : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isNext) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
              ],
            ),
    );
  }

  Widget _orderCardFromApi(Map<String, dynamic> order) {
    final pickupNo = order['pickup_no']?.toString() ?? 'N/A';
    final productName = order['product_details']?['name'] ?? 'Product';
    final int? pickupId = order['id'];
    final int? productId = order['product_details']?['id'];
    final int? senderAddressId = order['sender_address']?['id'];
    final resolvedState = resolveOrderState(order);

    String statusText;
    Color statusColor;
    switch (resolvedState) {
      case 'searching':
        statusText = 'SEARCHING';
        statusColor = Colors.orange;
        break;
      case 'pending':
        statusText = 'GOING TO PICKUP';
        statusColor = Colors.teal;
        break;
      case 'arrived':
        statusText = 'ARRIVED AT PICKUP';
        statusColor = Colors.blue;
        break;
      case 'picked_up':
        statusText = 'PICKED UP';
        statusColor = Colors.indigo;
        break;
      case 'in_transit':
        statusText = 'IN TRANSIT';
        statusColor = Colors.blueAccent;
        break;
      case 'arrived_at_drop':
        statusText = 'ARRIVED AT DROP';
        statusColor = Colors.green;
        break;
      case 'delivered':
        statusText = 'DELIVERED';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = 'CANCELLED';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'UNKNOWN';
        statusColor = Colors.grey;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _orderHeader(
            icon: Icons.inventory_2,
            title: productName,
            orderId: pickupNo,
            status: statusText,
            statusColor: statusColor,
          ),
          const SizedBox(height: 12),
          _infoTile(
            Icons.info,
            'Status',
            _getStatusDescription(resolvedState, order),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildHelpButton(order),
              if (_selectedTab != 0)
                const SizedBox(width: 8), 

              Expanded(
                child: _buildActionButtons(
                  order,
                  pickupId,
                  productId,
                  senderAddressId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton(Map<String, dynamic> order) {
    if (_selectedTab == 0) {
      return const SizedBox.shrink(); 
    }

    return GestureDetector(
      onTap: () => _showComplaintBottomSheet(context, order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, color: ColorConstants.red, size: 18),
            const SizedBox(width: 4),
            Text(
              'Help',
              style: TextStyle(
                color: ColorConstants.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(String state, Map<String, dynamic> order) {
    switch (state) {
      case 'searching':
        return 'Searching for a delivery carrier';
      case 'pending':
        return 'Carrier accepted and is heading to pickup';
      case 'arrived':
        return 'Carrier arrived at pickup location';
      case 'picked_up':
        return 'Tracking No: ${order["shipment_status"]?["carrier_tracking_no"] ?? "-"}';
      case 'in_transit':
        return 'Order is in transit to delivery location';
      case 'arrived_at_drop':
        return 'Carrier arrived at drop location';
      case 'delivered':
        return 'Delivered At: ${order["shipment_status"]?["delivered_at"] ?? "-"}';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Unknown status';
    }
  }

  Widget _buildActionButtons(
    Map<String, dynamic> order,
    int? pickupId,
    int? productId,
    int? senderAddressId,
  ) {
    switch (_selectedTab) {
      case 0:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditOrder(
                      productId: productId!,
                      senderAddressId: senderAddressId!,
                      pickupId: pickupId!,
                    ),
                  ),
                ).then((_) => _onRefresh()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Edit', style: TextStyle(color: Colors.blue)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(pickupId: pickupId!),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Details'),
              ),
            ),
          ],
        );
      case 1:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(pickupId: pickupId!),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Details'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(
                      pickupId: pickupId!,
                      orderData: order,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Track',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(pickupId: pickupId!),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Details'),
              ),
            ),
          ],
        );
    }
  }

  Widget _orderHeader({
    required IconData icon,
    required String title,
    required String orderId,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xffFFF3E0),
          child: Icon(icon, color: statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEEF2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: BoxBorder.all(color: ColorConstants.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Future<void> _showComplaintBottomSheet(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final pickupNo = order['pickup_no']?.toString() ?? 'N/A';
    final productName = order['product_details']?['name'] ?? 'Product';
    final int? pickupId = order['id'];

    logger.i(
      '🔍 Order data for complaint: ${order.keys}',
    ); 

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ComplaintBottomSheet(
          pickupId: pickupId,
          orderId: pickupNo,
          productName: productName,
          orderData: order, 
        ),
      ),
    );

    if (result == true) {
      logger.i('Complaint submitted successfully');
    }
  }
}
