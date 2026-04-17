import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/model/drop_orders.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/view/Shop/shop_detailedroders.dart';

class ShopDropOrdersScreen extends StatefulWidget {
  const ShopDropOrdersScreen({super.key});

  @override
  State<ShopDropOrdersScreen> createState() => _ShopDropOrdersScreenState();
}

class _ShopDropOrdersScreenState extends State<ShopDropOrdersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  final Logger logger = Logger();

  late TabController _tabController;
  int _currentTabIndex = 0;

  List<ShopDropOrder> incomingOrders = [];
  List<ShopDropOrder> inShopOrders = [];
  List<ShopDropOrder> outgoingOrders = [];

  bool isLoadingIncoming = false;
  bool isLoadingInShop = false;
  bool isLoadingOutgoing = false;

  bool hasMoreIncoming = true;
  bool hasMoreInShop = true;
  bool hasMoreOutgoing = true;

  int currentPage = 1;

  int totalCountIncoming = 0;
  int totalCountInShop = 0;
  int totalCountOutgoing = 0;

  bool isLoadingMore = false;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollControllerIncoming = ScrollController();
  final ScrollController _scrollControllerInShop = ScrollController();
  final ScrollController _scrollControllerOutgoing = ScrollController();
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchOrders();

    _scrollControllerIncoming.addListener(_scrollListener);
    _scrollControllerInShop.addListener(_scrollListener);
    _scrollControllerOutgoing.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollControllerIncoming.dispose();
    _scrollControllerInShop.dispose();
    _scrollControllerOutgoing.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _scrollListener() {
    ScrollController controller;
    switch (_currentTabIndex) {
      case 0:
        controller = _scrollControllerIncoming;
        break;
      case 1:
        controller = _scrollControllerInShop;
        break;
      default:
        controller = _scrollControllerOutgoing;
    }

    if (!isLoadingMore &&
        (hasMoreIncoming || hasMoreInShop || hasMoreOutgoing)) {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        _fetchOrders(loadMore: true);
      }
    }
  }

  Future<void> _fetchOrders({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore) return;
      setState(() => isLoadingMore = true);
      currentPage++;
    } else {
      setState(() {
        isLoadingIncoming = true;
        isLoadingInShop = true;
        isLoadingOutgoing = true;
        currentPage = 1;
      });
    }

    try {
      final response = await apiService.getShopDropOrders(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: currentPage,
        startDate: _startDate,
        endDate: _endDate,
        statusFilter: null,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final int totalCount = data['count'] ?? 0;
        final bool hasNext = data['next'] != null;

        final rawResults = data['results'];
        final List<dynamic> sections = (rawResults is Map)
            ? (rawResults['sections'] ?? [])
            : [];

        List<ShopDropOrder> extractItems(String key) {
          final section = sections.firstWhere(
            (s) => s['key'] == key,
            orElse: () => null,
          );
          final List<dynamic> items = section?['items'] ?? [];
          return items.map((json) => ShopDropOrder.fromJson(json)).toList();
        }

        int extractCount(String key) {
          final section = sections.firstWhere(
            (s) => s['key'] == key,
            orElse: () => null,
          );
          return section?['count'] ?? 0;
        }

       
        final newIncoming = extractItems('coming_to_shop');
        final newInShop = extractItems('dropped_at_shop');
        final newOutgoing = extractItems(
          'gone_from_shop',
        ); 

        setState(() {
          if (loadMore) {
            incomingOrders = [...incomingOrders, ...newIncoming];
            inShopOrders = [...inShopOrders, ...newInShop];
            outgoingOrders = [...outgoingOrders, ...newOutgoing];
            totalCountIncoming += extractCount('coming_to_shop');
            totalCountInShop += extractCount('dropped_at_shop');
            totalCountOutgoing += extractCount('gone_from_shop');
          } else {
            incomingOrders = newIncoming;
            inShopOrders = newInShop;
            outgoingOrders = newOutgoing;
            totalCountIncoming = extractCount('coming_to_shop');
            totalCountInShop = extractCount('dropped_at_shop');
            totalCountOutgoing = extractCount('gone_from_shop');
          }

          hasMoreIncoming = hasMoreInShop = hasMoreOutgoing = hasNext;
          isLoadingIncoming = isLoadingInShop = isLoadingOutgoing = false;
          isLoadingMore = false;
        });

        print(
          "✅ Loaded - Incoming: ${incomingOrders.length}, "
          "InShop: ${inShopOrders.length}, "
          "Outgoing: ${outgoingOrders.length}, "
          "Total: $totalCount, HasNext: $hasNext",
        );
      } else {
        setState(() {
          incomingOrders = inShopOrders = outgoingOrders = [];
          totalCountIncoming = totalCountInShop = totalCountOutgoing = 0;
          isLoadingIncoming = isLoadingInShop = isLoadingOutgoing = false;
          isLoadingMore = false;
        });
        _showErrorSnackBar(response['error'] ?? 'Failed to load orders');
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        incomingOrders = inShopOrders = outgoingOrders = [];
        isLoadingIncoming = isLoadingInShop = isLoadingOutgoing = false;
        isLoadingMore = false;
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applyFilters() {
    _searchFocusNode.unfocus();
    setState(() {
      incomingOrders = [];
      inShopOrders = [];
      outgoingOrders = [];
      currentPage = 1;
      hasMoreIncoming = true;
      hasMoreInShop = true;
      hasMoreOutgoing = true;
    });
    _fetchOrders();
  }

  void _clearFilters() {
    _searchFocusNode.unfocus();
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      incomingOrders = [];
      inShopOrders = [];
      outgoingOrders = [];
      currentPage = 1;
      hasMoreIncoming = true;
      hasMoreInShop = true;
      hasMoreOutgoing = true;
    });
    _fetchOrders();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _applyFilters();
    });
  }

  Future<void> _selectStartDate() async {
    _searchFocusNode.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: const Color(0xFFE63946),
          colorScheme: const ColorScheme.light(primary: Color(0xFFE63946)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      setState(() => _startDate = dateOnly);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    _searchFocusNode.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: const Color(0xFFE63946),
          colorScheme: const ColorScheme.light(primary: Color(0xFFE63946)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dateOnly = DateTime(picked.year, picked.month, picked.day);
      setState(() => _endDate = dateOnly);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    _searchFocusNode.unfocus();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _refreshCurrentTab() async {
    setState(() {
      incomingOrders = [];
      inShopOrders = [];
      outgoingOrders = [];
      currentPage = 1;
      hasMoreIncoming = true;
      hasMoreInShop = true;
      hasMoreOutgoing = true;
    });
    await _fetchOrders();
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  String _formatShortDateFromString(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      return _formatShortDate(
        DateFormat('dd MMM yyyy, hh:mm a').parse(dateString),
      );
    } catch (_) {
      try {
        return _formatShortDate(DateTime.parse(dateString));
      } catch (_) {
        return dateString;
      }
    }
  }

  String _formatTimeFromString(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      return _formatTime(DateFormat('dd MMM yyyy, hh:mm a').parse(dateString));
    } catch (_) {
      try {
        return _formatTime(DateTime.parse(dateString));
      } catch (_) {
        return '';
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'coming_to_shop':
        return Colors.orange;
      case 'dropped_at_shop':
        return Colors.blue;
      case 'gone_from_shop':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFormattedStatus(String status) {
    switch (status) {
      case 'coming_to_shop':
        return 'Incoming';
      case 'dropped_at_shop':
        return 'In Shop';
      case 'gone_from_shop':
        return 'Gone';
      default:
        return status;
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildExpandedTab(
            0,
            Icons.arrow_downward,
            'Incoming',
            totalCountIncoming,
          ),
          _buildExpandedTab(1, Icons.store, 'In Shop', totalCountInShop),
          _buildExpandedTab(2, Icons.arrow_upward, 'Gone', totalCountOutgoing),
        ],
      ),
    );
  }

  Widget _buildExpandedTab(int index, IconData icon, String label, int count) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE63946) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color:
                          (isSelected ? Colors.white : const Color(0xFFE63946))
                              .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFE63946),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by tracking number...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE63946)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFFE63946),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _startDate != null
                                    ? _dateFormat.format(_startDate!)
                                    : 'Select',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFFE63946),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _endDate != null
                                    ? _dateFormat.format(_endDate!)
                                    : 'Select',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  tooltip: 'Clear date filter',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    List<ShopDropOrder> orders,
    bool isLoading,
    int tabIndex,
  ) {
    if (isLoading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE63946)),
      );
    }

    if (!isLoading && orders.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: const Color(0xFFE63946),
      child: ListView.builder(
        controller: tabIndex == 0
            ? _scrollControllerIncoming
            : tabIndex == 1
            ? _scrollControllerInShop
            : _scrollControllerOutgoing,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: orders.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == orders.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE63946)),
              ),
            );
          }
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isNotEmpty
                ? 'No orders match your search'
                : (_startDate != null || _endDate != null)
                ? 'No orders in selected date range'
                : 'No orders found',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (_searchController.text.isNotEmpty ||
              _startDate != null ||
              _endDate != null)
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE63946),
              ),
              child: const Text('Clear all filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ShopDropOrder order) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDropOrderDetailScreen(orderId: order.id),
          ),
        ).then((_) => _refreshCurrentTab());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFE63946).withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Color(0xFFE63946),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.trackingNo,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Carrier',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.carrierName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              order.carrierPhone,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(
                                order.status,
                              ).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                order.status == 'gone_from_shop'
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 12,
                                color: _getStatusColor(order.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getFormattedStatus(order.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sender',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.senderName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                order.senderPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: order.arrivedAtShopAt.isNotEmpty
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: order.arrivedAtShopAt.isNotEmpty
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Arrived',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (order.arrivedAtShopAt.isNotEmpty) ...[
                                    Text(
                                      _formatShortDateFromString(
                                        order.arrivedAtShopAt,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatTimeFromString(
                                        order.arrivedAtShopAt,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ] else
                                    const Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: order.droppedAtShopAt.isNotEmpty
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 14,
                                color: order.droppedAtShopAt.isNotEmpty
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dropped',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (order.droppedAtShopAt.isNotEmpty) ...[
                                    Text(
                                      _formatShortDateFromString(
                                        order.droppedAtShopAt,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatTimeFromString(
                                        order.droppedAtShopAt,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ] else
                                    const Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Created: ${_formatShortDateFromString(order.createdAt)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 15,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFE63946),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  _buildSearchAndFilters(),
                ],
              ),
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(incomingOrders, isLoadingIncoming, 0),
                  _buildOrderList(inShopOrders, isLoadingInShop, 1),
                  _buildOrderList(outgoingOrders, isLoadingOutgoing, 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
