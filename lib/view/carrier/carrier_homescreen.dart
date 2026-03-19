import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/model/carrier_orders.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

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

  int _todayCompleted = 0;
  int _totalCompleted = 0;
  bool _isLoadingCounts = true;
  String? _countsError;

  List<CompletedOrder> _completedOrders = [];
  bool _isLoadingChart = true;
  String? _chartError;

  String _selectedRange = 'week';

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

  @override
  void initState() {
    super.initState();
    _loadDashboardCounts();
    _loadChartData();
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
        } else {
          _countsError = result['error'] ?? 'Unknown error';
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
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoadingChart = true;
      _chartError = null;
    });

    try {
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (_selectedRange) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      List<CompletedOrder> allOrders = [];
      String? nextUrl;
      int pageCount = 0;

      do {
        pageCount++;
        print('📄 Fetching page $pageCount...');

        final result = await _apiService.getCarrierCompletedOrders(
          page: pageCount,
          startDate: startDate,
          endDate: now,
          pageSize: 100,
        );

        if (result.containsKey('orders')) {
          List<CompletedOrder> pageOrders =
              result['orders'] as List<CompletedOrder>;
          allOrders.addAll(pageOrders);
          print('✅ Page $pageCount has ${pageOrders.length} orders');
          nextUrl = result['nextUrl'] as String?;
          bool hasNext = result['hasNext'] as bool? ?? false;
          print('📊 Next URL: $nextUrl, Has Next: $hasNext');
          if (nextUrl == null || nextUrl.isEmpty || !hasNext) {
            break;
          }
        } else {
          print('❌ No "orders" key in response');
          break;
        }
        if (pageCount > 20) {
          print('⚠️ Breaking pagination loop - too many pages');
          break;
        }
      // ignore: unnecessary_null_comparison
      } while (nextUrl != null && nextUrl.isNotEmpty);

      print('🎯 FINAL: Loaded ${allOrders.length} orders');

      setState(() {
        _completedOrders = allOrders;
        _isLoadingChart = false;
      });
    } catch (e) {
      print('🔥 Chart data error: $e');
      setState(() {
        _isLoadingChart = false;
        _chartError = e.toString();
        _completedOrders = [];
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardCounts();
    await _loadChartData();
  }

  Map<DateTime, int> _getOrdersByDay() {
    final Map<DateTime, int> ordersByDay = {};

    for (var order in _completedOrders) {
      if (order.deliveredAt != null) {
        DateTime date = DateTime(
          order.deliveredAt!.year,
          order.deliveredAt!.month,
          order.deliveredAt!.day,
        );

        ordersByDay[date] = (ordersByDay[date] ?? 0) + 1;
      }
    }

    final sortedMap = SplayTreeMap<DateTime, int>.from(
      ordersByDay,
      (a, b) => a.compareTo(b),
    );

    return sortedMap;
  }

  List<FlSpot> _getChartSpots() {
    final ordersByDay = _getOrdersByDay();

    if (ordersByDay.isEmpty) {
      return [];
    }
    final sortedDates = ordersByDay.keys.toList();
    if (sortedDates.length > 1) {
      final List<FlSpot> continuousSpots = [];
      final firstDate = sortedDates.first;
      final lastDate = sortedDates.last;

      int dayIndex = 0;
      DateTime currentDate = firstDate;

      while (currentDate.isBefore(lastDate) ||
          currentDate.isAtSameMomentAs(lastDate)) {
        int count = ordersByDay[currentDate] ?? 0;
        continuousSpots.add(FlSpot(dayIndex.toDouble(), count.toDouble()));
        currentDate = currentDate.add(const Duration(days: 1));
        dayIndex++;
      }

      return continuousSpots;
    }

    return sortedDates.asMap().entries.map((entry) {
      int index = entry.key;
      DateTime date = entry.value;
      return FlSpot(index.toDouble(), ordersByDay[date]!.toDouble());
    }).toList();
  }

  Widget _buildChartTitle() {
    String title;
    switch (_selectedRange) {
      case 'week':
        title = 'Last 7 Days';
        break;
      case 'month':
        title = 'Last 30 Days';
        break;
      case 'year':
        title = 'Last 12 Months';
        break;
      default:
        title = 'Delivery History';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildRangeChip('Week', 'week'),
              const SizedBox(width: 4),
              _buildRangeChip('Month', 'month'),
              const SizedBox(width: 4),
              _buildRangeChip('Year', 'year'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label, String value) {
    bool isSelected = _selectedRange == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRange = value);
        _loadChartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = _getChartSpots();

    if (_isLoadingChart) {
      return const Center(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
    }

    if (_chartError != null || spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 40,
                color: Colors.red.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                _chartError ?? 'No delivery data available',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.red.withOpacity(0.1), strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.red.withOpacity(0.1), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final ordersByDay = _getOrdersByDay();
                  final sortedDates = ordersByDay.keys.toList()..sort();

                  if (value.toInt() >= 0 &&
                      value.toInt() < sortedDates.length) {
                    final date = sortedDates[value.toInt()];

                    String text;
                    if (_selectedRange == 'year') {
                      text = DateFormat('MMM').format(date);
                    } else {
                      text = DateFormat('dd').format(date);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: spots.isEmpty ? 1 : (spots.length - 1).toDouble(),
          minY: 0,
          maxY: spots.isEmpty
              ? 1
              : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.red,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                              const Text(
                                "Hello",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "👋",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
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
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          "Today's Deliveries",
                          _isLoadingCounts ? null : _todayCompleted.toString(),
                          Icons.local_shipping,
                          isLoading: _isLoadingCounts,
                          error: _countsError,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          "Total Completed",
                          _isLoadingCounts ? null : _totalCompleted.toString(),
                          Icons.check_circle,
                          isLoading: _isLoadingCounts,
                          error: _countsError,
                        ),
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
                      gradient: LinearGradient(
                        colors: [Colors.red.shade700, Colors.red.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartTitle(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildLineChart(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_completedOrders.isNotEmpty && !_isLoadingChart)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Total Orders',
                                  _completedOrders.length.toString(),
                                  Icons.shopping_bag,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.red.withOpacity(0.2),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Avg/Day',
                                  _calculateAveragePerDay().toStringAsFixed(1),
                                  Icons.trending_up,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.red.withOpacity(0.2),
                              ),

                              Expanded(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPeakDayText(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                    const Text(
                                      'Peak Day',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getDateRangeText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MapEntry<DateTime, int>? _getPeakDay() {
    final ordersByDay = _getOrdersByDay();
    if (ordersByDay.isEmpty) return null;

    return ordersByDay.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  String _getPeakDayText() {
    final peakDay = _getPeakDay();
    if (peakDay == null) return 'No data';

    final date = peakDay.key;
    final count = peakDay.value;

    if (_selectedRange == 'year') {
      return '${DateFormat('MMM dd').format(date)} ($count)';
    } else {
      return '${DateFormat('EEE, dd MMM').format(date)} ($count)';
    }
  }

  double _calculateAveragePerDay() {
    if (_completedOrders.isEmpty) return 0;
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedRange) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    int totalDays = now.difference(startDate).inDays;
    if (totalDays < 1) totalDays = 1;

    return _completedOrders.length / totalDays;
  }

  String _getDateRangeText() {
    if (_completedOrders.isEmpty) return 'No data';

    DateTime? earliest;
    DateTime? latest;

    for (var order in _completedOrders) {
      if (order.deliveredAt != null) {
        if (earliest == null || order.deliveredAt!.isBefore(earliest)) {
          earliest = order.deliveredAt;
        }
        if (latest == null || order.deliveredAt!.isAfter(latest)) {
          latest = order.deliveredAt;
        }
      }
    }

    if (earliest == null || latest == null) return 'No date range';

    return '${DateFormat('dd MMM').format(earliest)} - ${DateFormat('dd MMM yyyy').format(latest)}';
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _infoCard(
    String title,
    String? value,
    IconData icon, {
    bool isLoading = false,
    String? error,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
