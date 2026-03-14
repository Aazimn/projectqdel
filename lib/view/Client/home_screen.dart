import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:projectqdel/view/Client/order_detailed.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ApiService _api = ApiService();

  UserModel? user;
  bool profileLoading = true;

  // Server-side counts from API `count` field
  int pendingCount = 0;
  int activeCount = 0;
  int completedCount = 0;
  bool countsLoading = true;

  // Active orders for home preview (page 1 only, max 3 shown)
  List<dynamic> activeOrders = [];
  bool activeOrdersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadCounts(), _loadActiveOrders()]);
  }

  Future<void> _onRefresh() async => _loadAll();

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => profileLoading = true);
    try {
      final result = await _api.getMyProfile();
      setState(() {
        user = result;
        profileLoading = false;
      });
    } catch (e) {
      setState(() => profileLoading = false);
    }
  }

  // ── Counts (3 parallel calls, read only `count`) ───────────────────────────
  Future<void> _loadCounts() async {
    setState(() => countsLoading = true);
    try {
      final results = await Future.wait([
        _api.getAcceptedOrders(page: 1, status: 'pending'),
        _api.getAcceptedOrders(page: 1, status: 'active'),
        _api.getAcceptedOrders(page: 1, status: 'completed'),
      ]);
      setState(() {
        pendingCount = _extractCount(results[0]);
        activeCount = _extractCount(results[1]);
        completedCount = _extractCount(results[2]);
        countsLoading = false;
      });
    } catch (e) {
      print('❌ Count load error: $e');
      setState(() => countsLoading = false);
    }
  }

  // ── Active orders preview ──────────────────────────────────────────────────
  Future<void> _loadActiveOrders() async {
    setState(() => activeOrdersLoading = true);
    try {
      final response = await _api.getAcceptedOrders(page: 1, status: 'active');
      setState(() {
        activeOrders = _extractOrders(response);
        activeOrdersLoading = false;
      });
    } catch (e) {
      print('❌ Active orders error: $e');
      setState(() {
        activeOrders = [];
        activeOrdersLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _extractCount(dynamic response) {
    if (response is Map) {
      final c = response['count'];
      if (c != null) return c is int ? c : (c as num).toInt();
    }
    if (response is List) return response.length;
    return 0;
  }

  List<dynamic> _extractOrders(dynamic response) {
    if (response is Map) return (response['data'] as List?) ?? [];
    if (response is List) return response;
    return [];
  }

  String resolveOrderState(Map<String, dynamic> order) {
    final shipment = order['shipment_status'];
    if (shipment == null) return 'unknown';
    return shipment['status']?.toString().toLowerCase() ?? 'unknown';
  }

  void _navigateToOrdersTab(int tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDashboard(initialIndex: 2, ordersInitialTab: tab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: ColorConstants.red,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 4.0,
        showChildOpacityTransition: true,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildStatusCards(),
                  const SizedBox(height: 20),
                  _buildActiveOrdersSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = user != null
        ? '${user!.firstName} ${user!.lastName}'.toUpperCase()
        : 'GUEST USER';

    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        color: ColorConstants.red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: ColorConstants.red, size: 32),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome 👋', style: TextStyle(color: Colors.white70)),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statusCard(
          title: 'Searching',
          count: countsLoading ? '...' : pendingCount.toString(),
          icon: Icons.search,
          subtitle: 'Finding partners',
          onTap: () => _navigateToOrdersTab(0),
        ),
        _statusCard(
          title: 'Active',
          count: countsLoading ? '...' : activeCount.toString(),
          icon: Icons.local_shipping,
          subtitle: 'In progress',
          onTap: () => _navigateToOrdersTab(1),
        ),
        _statusCard(
          title: 'Completed',
          count: countsLoading ? '...' : completedCount.toString(),
          icon: Icons.check_circle,
          subtitle: 'Delivered',
          onTap: () => _navigateToOrdersTab(2),
        ),
      ],
    );
  }

  Widget _statusCard({
    required String title,
    required String count,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: ColorConstants.red, size: 28),
            const SizedBox(height: 5),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorConstants.red,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!activeOrdersLoading && activeCount > 0)
              TextButton(
                onPressed: () => _navigateToOrdersTab(1),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeOrdersLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.red),
              ),
            ),
          )
        else if (activeOrders.isEmpty)
          _buildEmptyState()
        else ...[
          ...activeOrders.take(3).map(_buildOrderCard),
          if (activeCount > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: TextButton(
                  onPressed: () => _navigateToOrdersTab(1),
                  child: Text(
                    '+ ${activeCount - 3} more active orders',
                    style: const TextStyle(color: ColorConstants.red),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No active orders',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderId = order['pickup_no']?.toString() ?? 'N/A';
    final productName = order['product_details']?['name'] ?? 'Product';
    final pickupId = order['id'];
    final state = resolveOrderState(order);

    String statusText;
    Color statusColor;
    switch (state) {
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
      default:
        statusText = state.toUpperCase();
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.red.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (pickupId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(pickupId: pickupId),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory, size: 28, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
