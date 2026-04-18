import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/carrier_orders.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_orderdetails.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ApiService _apiService = ApiService();
  List<CompletedOrder> _completedOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  bool _isLoadingMore = false;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _loadCompletedOrders();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getCarrierCompletedOrders(
      page: _currentPage,
      pageSize: 10,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _isLoading = false;

      if (result.containsKey('error')) {
        _errorMessage = result['error'];
        _completedOrders = [];
      } else {
        _completedOrders = result['orders'] as List<CompletedOrder>;
        _hasNextPage = result['hasNext'];
        _hasPreviousPage = result['hasPrevious'];
        _totalPages = result['totalPages'];
        _totalCount = result['count'];

        print('📊 Page $_currentPage of $_totalPages');
        print('📊 Total Orders: $_totalCount');
        print('📊 Orders on this page: ${_completedOrders.length}');
      }
    });
  }

  Future<void> _goToNextPage() async {
    if (!_hasNextPage || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final result = await _apiService.getCarrierCompletedOrders(
      page: _currentPage,
      pageSize: 10,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _isLoadingMore = false;

      if (!result.containsKey('error')) {
        _completedOrders = result['orders'] as List<CompletedOrder>;
        _hasNextPage = result['hasNext'];
        _hasPreviousPage = result['hasPrevious'];
        _totalPages = result['totalPages'];
      }
    });
  }

  Future<void> _goToPreviousPage() async {
    if (!_hasPreviousPage || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage--;
    });

    final result = await _apiService.getCarrierCompletedOrders(
      page: _currentPage,
      pageSize: 10,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _isLoadingMore = false;
      if (!result.containsKey('error')) {
        _completedOrders = result['orders'] as List<CompletedOrder>;
        _hasNextPage = result['hasNext'];
        _hasPreviousPage = result['hasPrevious'];
        _totalPages = result['totalPages'];
      }
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _currentPage = 1;
      _completedOrders = [];
    });
    await _loadCompletedOrders();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 1;
        });
        _refreshOrders();
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _searchFocusNode.unfocus();
    _refreshOrders();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    _searchFocusNode.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _currentPage = 1;
      });
      _refreshOrders();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    _searchFocusNode.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _currentPage = 1;
      });
      _refreshOrders();
    }
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('hh:mm a').format(date);
  }

  String _getStatusDisplayText(String? status) {
    if (status == 'Dropped at Shop') {
      return 'Drop';
    }
    return status ?? 'Unknown';
  }

  Widget _buildModernPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasPreviousPage && !_isLoadingMore
                  ? _goToPreviousPage
                  : null,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _hasPreviousPage && !_isLoadingMore
                      ? Colors.red
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: _hasPreviousPage && !_isLoadingMore
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Prev',
                      style: TextStyle(
                        color: _hasPreviousPage && !_isLoadingMore
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade100, Colors.red.shade50],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_currentPage',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'of $_totalPages',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _hasNextPage && !_isLoadingMore ? _goToNextPage : null,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _hasNextPage && !_isLoadingMore
                      ? Colors.red
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: _hasNextPage && !_isLoadingMore
                            ? Colors.white
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _hasNextPage && !_isLoadingMore
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: 25,
                ),
                decoration: const BoxDecoration(
                  color: ColorConstants.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search by order ID or phone...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.red,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocusNode.unfocus();
                                    _refreshOrders();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Start Date',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          _startDate != null
                                              ? _dateFormat.format(_startDate!)
                                              : 'Select',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
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
                            onTap: () => _selectEndDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'End Date',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          _endDate != null
                                              ? _dateFormat.format(_endDate!)
                                              : 'Select',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
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
                        if (_startDate != null ||
                            _endDate != null ||
                            _searchController.text.isNotEmpty)
                          IconButton(
                            onPressed: _clearAllFilters,
                            icon: const Icon(
                              Icons.clear_all,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Clear all filters',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Completed Deliveries",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Total $_totalCount',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _completedOrders.isEmpty
                    ? _buildEmptyWidget()
                    : _buildScrollableContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
              _searchController.text.isNotEmpty ||
                      _startDate != null ||
                      _endDate != null
                  ? 'No orders match your filters'
                  : 'No completed deliveries yet',
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
                onPressed: _clearAllFilters,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear all filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: Colors.red,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ..._completedOrders.map((order) => _buildOrderCard(order)).toList(),

          if (_completedOrders.isNotEmpty && !_isLoadingMore)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: _buildModernPaginationControls(),
            ),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CompletedOrder order) {
    final isDropOrder = order.isDroppedAtShop;

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailScreen(order: order, orderId: order.id),
          ),
        );
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
                colors: [Colors.white, Colors.red.withOpacity(0.05)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order #${order.id}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Pickup ID: ${order.pickupId}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isDropOrder && order.droppedAtShopAt != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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
                                    _getStatusIcon(order.status),
                                    size: 14,
                                    color: _getStatusColor(order.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.getDisplayStatus(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(order.droppedAtShopAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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
                                _getStatusIcon(order.status),
                                size: 14,
                                color: _getStatusColor(order.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.getDisplayStatus(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                                order.senderName?.toUpperCase() ??
                                    "User Name Not Found",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                order.senderPhone,
                                style: const TextStyle(
                                  fontSize: 14,
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: order.pickedAt != null
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.black54.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: order.pickedAt != null
                                    ? Colors.orange
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Picked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (order.pickedAt != null) ...[
                                    Text(
                                      _formatShortDate(order.pickedAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(order.pickedAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ] else
                                    const Text(
                                      'Not picked',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),

                      Expanded(
                        child: isDropOrder
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: order.droppedAtShopAt != null
                                          ? const Color.fromARGB(
                                              255,
                                              206,
                                              70,
                                              70,
                                            ).withOpacity(0.1)
                                          : Colors.black54.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.store,
                                      size: 16,
                                      color: order.droppedAtShopAt != null
                                          ? const Color.fromARGB(
                                              255,
                                              206,
                                              70,
                                              70,
                                            )
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Drop',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (order.droppedAtShopAt != null) ...[
                                          Text(
                                            _formatShortDate(
                                              order.droppedAtShopAt,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(order.droppedAtShopAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ] else
                                          const Text(
                                            'Not dropped',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: order.deliveredAt != null
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.black54.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: order.deliveredAt != null
                                          ? Colors.green
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Delivered',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (order.deliveredAt != null) ...[
                                          Text(
                                            _formatShortDate(order.deliveredAt),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(order.deliveredAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ] else
                                          const Text(
                                            'Not delivered',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
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
                      Icon(Icons.access_time, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        'Created: ${_formatShortDate(order.createdAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Dropped at Shop':
        return const Color.fromARGB(255, 206, 70, 70);
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'Dropped at Shop':
        return Icons.store;
      case 'Pending':
        return Icons.pending;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
