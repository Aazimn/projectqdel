import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:logger/logger.dart';

class ShopDropOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const ShopDropOrderDetailScreen({super.key, required this.orderId});

  @override
  State<ShopDropOrderDetailScreen> createState() =>
      _ShopDropOrderDetailScreenState();
}

class _ShopDropOrderDetailScreenState extends State<ShopDropOrderDetailScreen> {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;

  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getShopDropOrderDetail(widget.orderId);

    if (result['success'] == true) {
      setState(() {
        _orderData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Failed to load order details';
        _isLoading = false;
      });
    }
  }


  // int get _shopdropId => _orderData?['shopdrop_id'] ?? 0;
  String get _shopStatus => _orderData?['shop_status'] ?? '';
  // String get _shopStatusDisplay => _orderData?['shop_status_display'] ?? '';
  String? get _image => _orderData?['image'];

  String get _dropCarrierName => _orderData?['drop_carrier_name'] ?? '';
  String get _dropCarrierPhone => _orderData?['drop_carrier_phone'] ?? '';
  String get _dropCarrierTrackingNo =>
      _orderData?['drop_carrier_tracking_no'] ?? '';
  // String get _dropCarrierStatus => _orderData?['drop_carrier_status'] ?? '';
  String get _dropCarrierStatusDisplay =>
      _orderData?['drop_carrier_status_display'] ?? '';

  String? get _nextCarrierName => _orderData?['next_carrier_name'];
  String? get _nextCarrierPhone => _orderData?['next_carrier_phone'];
  String? get _nextCarrierTrackingNo => _orderData?['next_carrier_tracking_no'];
  // String? get _nextCarrierStatus => _orderData?['next_carrier_status'];
  String? get _nextCarrierStatusDisplay =>
      _orderData?['next_carrier_status_display'];

  // int get _pickupId => _orderData?['pickup_id'] ?? 0;
  String get _pickupNo => _orderData?['pickup_no'] ?? '';

  String get _senderName => _orderData?['sender_name'] ?? '';
  String get _senderPhone => _orderData?['sender_phone'] ?? '';

  String? get _shopName => _orderData?['shop_name'];
  String? get _shopPhone => _orderData?['shop_phone'];

  String? get _dropAssignedAt => _orderData?['drop_assigned_at'];
  String? get _arrivedAtShopAt => _orderData?['arrived_at_shop_at'];
  String? get _droppedAtShopAt => _orderData?['dropped_at_shop_at'];
  String? get _dispatchedFromShopAt => _orderData?['dispatched_from_shop_at'];
  String get _createdAt => _orderData?['created_at'] ?? '';
  // String get _updatedAt => _orderData?['updated_at'] ?? '';

  bool get _hasNextCarrier =>
      _nextCarrierName != null && _nextCarrierName!.isNotEmpty;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'coming_to_shop':
      case 'drop_assigned':
      case 'arrived_at_shop':
        return Colors.orange;
      case 'dropped_at_shop':
        return Colors.blue;
      case 'dispatched_from_shop':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFormattedStatus(String status) {
    switch (status) {
      case 'coming_to_shop':
        return 'Coming to Shop';
      case 'dropped_at_shop':
        return 'In Shop';
      case 'dispatched_from_shop':
        return 'Dispatched';
      case 'drop_assigned':
        return 'Drop Assigned';
      case 'arrived_at_shop':
        return 'Arrived at Shop';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFE63946),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrderDetail,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _orderData == null
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFE63946)),
          SizedBox(height: 16),
          Text(
            'Loading order details...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              size: 64,
              color: Color(0xFFE63946),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchOrderDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No order details found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildOrderInfoCard(),
          const SizedBox(height: 16),
          _buildSenderInfoCard(),
          const SizedBox(height: 16),
          _buildJourneyTimeline(),
          const SizedBox(height: 16),
          if (_image != null && _image!.isNotEmpty) _buildImageCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(_shopStatus),
            _getStatusColor(_shopStatus).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_shopStatus).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _shopStatus == 'dispatched_from_shop'
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Status',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedStatus(_shopStatus),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Tracking Number',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dropCarrierTrackingNo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: Color(0xFFE63946),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.qr_code,
              label: 'Pickup Number',
              value: _pickupNo,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.shop,
              label: 'Shop Name',
              value: _shopName ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Shop Phone',
              value: _shopPhone ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Created At',
              value: _formatDateTime(_createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sender Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Name',
              value: _senderName.toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: _senderPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyTimeline() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    size: 20,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildJourneyStep(
              stepNumber: 1,
              title: 'Order Created',
              icon: Icons.create,
              dateTime: _createdAt,
              isCompleted: true,
              carrierName: null,
              carrierPhone: null,
              trackingNo: null,
              status: null,
            ),

            _buildConnector(isCompleted: _dropAssignedAt != null),

            _buildJourneyStep(
              stepNumber: 2,
              title: 'Drop Assigned',
              icon: Icons.assignment,
              dateTime: _dropAssignedAt,
              isCompleted: _dropAssignedAt != null,
              carrierName: _dropCarrierName,
              carrierPhone: _dropCarrierPhone,
              trackingNo: _dropCarrierTrackingNo,
              status: _dropCarrierStatusDisplay,
              isCarrierActive: true,
            ),

            _buildConnector(isCompleted: _arrivedAtShopAt != null),

            _buildJourneyStep(
              stepNumber: 3,
              title: 'Arrived at Shop',
              icon: Icons.location_on,
              dateTime: _arrivedAtShopAt,
              isCompleted: _arrivedAtShopAt != null,
              carrierName: null,
              carrierPhone: null,
              trackingNo: null,
              status: null,
            ),

            _buildConnector(isCompleted: _droppedAtShopAt != null),

            _buildJourneyStep(
              stepNumber: 4,
              title: 'Dropped at Shop',
              icon: Icons.inventory,
              dateTime: _droppedAtShopAt,
              isCompleted: _droppedAtShopAt != null,
              carrierName: null,
              carrierPhone: null,
              trackingNo: null,
              status: null,
            ),

            if (_hasNextCarrier) ...[
              _buildHandoverDivider(),

              _buildJourneyStep(
                stepNumber: 5,
                title: 'Picked Up by Next Carrier',
                icon: Icons.swap_horiz,
                dateTime: _dispatchedFromShopAt,
                isCompleted: _dispatchedFromShopAt != null,
                carrierName: _nextCarrierName,
                carrierPhone: _nextCarrierPhone,
                trackingNo: _nextCarrierTrackingNo,
                status: _nextCarrierStatusDisplay,
                isCarrierActive: true,
                isNewCarrier: true,
              ),

              _buildConnector(isCompleted: _dispatchedFromShopAt != null),

            
              _buildJourneyStep(
                stepNumber: 6,
                title: 'Dispatched from Shop',
                icon: Icons.delivery_dining,
                dateTime: _dispatchedFromShopAt,
                isCompleted: _dispatchedFromShopAt != null,
                carrierName: null,
                carrierPhone: null,
                trackingNo: null,
                status: null,
                isNewCarrier: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    String? dateTime,
    required bool isCompleted,
    String? carrierName,
    String? carrierPhone,
    String? trackingNo,
    String? status,
    bool isCarrierActive = false,
    // bool isCarrierComplete = false,
    bool isNewCarrier = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE63946).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isCompleted
                          ? const Color(0xFFE63946)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      if (dateTime != null && dateTime.isNotEmpty)
                        Text(
                          _formatDateTime(dateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),

       
                  if (isCarrierActive &&
                      carrierName != null &&
                      carrierName.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isNewCarrier
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isNewCarrier
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 16,
                                color: isNewCarrier
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isNewCarrier ? 'New Carrier' : 'Active Carrier',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isNewCarrier
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildCarrierDetailRow(
                            Icons.business,
                            'Name',
                            carrierName,
                          ),
                          const SizedBox(height: 6),
                          _buildCarrierDetailRow(
                            Icons.phone,
                            'Phone',
                            carrierPhone ?? 'N/A',
                          ),
                          if (trackingNo != null && trackingNo.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildCarrierDetailRow(
                              Icons.qr_code,
                              'Tracking No',
                              trackingNo,
                            ),
                          ],
                          if (status != null && status.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildCarrierDetailRow(
                              Icons.info_outline,
                              'Status',
                              status,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (!isCarrierActive && dateTime == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarrierDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        height: 30,
        width: 2,
        color: isCompleted ? const Color(0xFFE63946) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildHandoverDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: const Icon(Icons.swap_horiz, size: 24, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Carrier Handover',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    String getFullImageUrl(String imagePath) {
      if (imagePath.isEmpty) return '';
      if (imagePath.startsWith('http')) return imagePath;
      return '${_apiService.baseurl}$imagePath';
    }

    final imageUrl = getFullImageUrl(_image!);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    size: 20,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.zero,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE63946),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isAddress = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: isAddress ? 1.3 : 1,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'N/A';
    try {
      return _dateTimeFormat.format(DateTime.parse(dateTimeStr));
    } catch (_) {
      try {
        return _dateTimeFormat.format(
          DateFormat('dd MMM yyyy, hh:mm a').parse(dateTimeStr),
        );
      } catch (_) {
        return dateTimeStr;
      }
    }
  }
}
