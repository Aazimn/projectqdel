import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';

class CarrierHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToIndex;

  const CarrierHomeScreen({super.key, this.onNavigateToIndex});

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  final ApiService _apiService = ApiService();

  UserModel? user;
  bool profileLoading = true;

  // Dashboard counts
  int _todayCompleted = 0;
  int _totalCompleted = 0;
  bool _isLoadingCounts = true;
  String? _countsError;

  Future<void> _loadProfile() async {
    setState(() => profileLoading = true);
    try {
      final result = await _apiService.getMyProfile();
      setState(() {
        user = result;
        profileLoading = false;
      });
    } catch (e) {
      setState(() => profileLoading = false);
    }
  }

  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': 101,
      'pickupId': 201,
      'senderName': 'Rahul Sharma',
      'senderPhone': '+91 98765 43210',
      'status': 'delivered',
      'pickedAt': DateTime.now().subtract(const Duration(hours: 5)),
      'deliveredAt': DateTime.now().subtract(const Duration(hours: 2)),
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'destination': 'Ernakulam',
    },
    {
      'id': 102,
      'pickupId': 202,
      'senderName': 'Priya Menon',
      'senderPhone': '+91 87654 32109',
      'status': 'delivered',
      'pickedAt': DateTime.now().subtract(const Duration(hours: 8)),
      'deliveredAt': DateTime.now().subtract(const Duration(hours: 4)),
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'destination': 'Kochi',
    },
    {
      'id': 103,
      'pickupId': 203,
      'senderName': 'Arun Kumar',
      'senderPhone': '+91 76543 21098',
      'status': 'delivered',
      'pickedAt': DateTime.now().subtract(const Duration(hours: 12)),
      'deliveredAt': DateTime.now().subtract(const Duration(hours: 9)),
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'destination': 'Thrissur',
    },
    {
      'id': 104,
      'pickupId': 204,
      'senderName': 'Deepa Nair',
      'senderPhone': '+91 65432 10987',
      'status': 'delivered',
      'pickedAt': DateTime.now().subtract(const Duration(hours: 24)),
      'deliveredAt': DateTime.now().subtract(const Duration(hours: 20)),
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'destination': 'Kottayam',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardCounts();
    _loadProfile();
  }

  Future<void> _loadDashboardCounts() async {
    setState(() {
      _isLoadingCounts = true;
      _countsError = null;
    });

    try {
      final result = await _apiService.getCarrierDashboardCounts();

      setState(() {
        _isLoadingCounts = false;

        if (result['success'] == true) {
          _todayCompleted = result['todayCompleted'];
          _totalCompleted = result['totalCompleted'];
          print(
            '✅ Loaded counts - Today: $_todayCompleted, Total: $_totalCompleted',
          );
        } else {
          _countsError = result['error'] ?? 'Unknown error';
          print('❌ Error loading counts: $_countsError');
          _todayCompleted = 0;
          _totalCompleted = 0;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCounts = false;
        _countsError = e.toString();
        _todayCompleted = 0;
        _totalCompleted = 0;
      });
      print('🔥 Exception loading counts: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardCounts();
  }

  String _formatShortTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final name = user != null
        ? '${user!.firstName} ${user!.lastName}'.toUpperCase()
        : 'Carrier';
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.red,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Hello",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "👋",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Welcome back, Carrier 🚚",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.onNavigateToIndex != null) {
                          widget.onNavigateToIndex!(3);
                        }
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.person, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard(
                      "Today's Deliveries",
                      _isLoadingCounts ? null : _todayCompleted.toString(),
                      Icons.local_shipping,
                      isLoading: _isLoadingCounts,
                      error: _countsError,
                    ),
                    const SizedBox(width: 12),
                    _infoCard(
                      "Total Completed",
                      _isLoadingCounts ? null : _totalCompleted.toString(),
                      Icons.check_circle,
                      isLoading: _isLoadingCounts,
                      error: _countsError,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Earnings",
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "₹1,250",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Deliveries",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.onNavigateToIndex != null) {
                          widget.onNavigateToIndex!(2);
                        }
                      },
                      child: Container(
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
                        child: const Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: _recentOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent deliveries',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recentOrders.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final order = _recentOrders[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.red.withOpacity(0.02),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // Top row - Order ID and Status
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inventory,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Order #${order['id']}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.3,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 10,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'Delivered',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order['senderName'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              order['senderPhone'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [

                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 12,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Picked',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatShortTime(
                                                      order['pickedAt'],
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Icon(
                                        Icons.arrow_forward,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),

                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 12,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Delivered',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatShortTime(
                                                      order['deliveredAt'],
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
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

                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 10,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        order['destination'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
    String title,
    String? value,
    IconData icon, {
    bool isLoading = false,
    String? error,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.red, size: 24),
            const SizedBox(height: 5),
            if (isLoading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2,
                ),
              )
            else if (error != null)
              const Icon(Icons.error_outline, color: Colors.red, size: 20)
            else
              Text(
                value ?? '0',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
