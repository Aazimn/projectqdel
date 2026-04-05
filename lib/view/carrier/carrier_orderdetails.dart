// lib/view/Carrier/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/carrier_orders.dart';
import 'package:projectqdel/services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final CompletedOrder order;
  final int orderId; // Add this to fetch fresh data

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  CompletedOrder? _detailedOrder;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderDetail = await _apiService.getCarrierOrderDetail(
        widget.orderId,
      );

      setState(() {
        _isLoading = false;
        if (orderDetail != null) {
          _detailedOrder = orderDetail;
        } else {
          _errorMessage = 'Failed to load order details';
          // Fallback to the passed order if API fails
          _detailedOrder = widget.order;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
        _detailedOrder = widget.order; // Fallback
      });
    }
  }

  String _formatFullDateTime(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('dd MMM yyyy • hh:mm:ss a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: ColorConstants.red,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Order Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    final order = _detailedOrder ?? widget.order;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchOrderDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Order Status Card
                  _buildOrderStatusCard(order),
                  const SizedBox(height: 16),

                  // Sender Information Card with Address
                  _buildSenderInfoCard(order),
                  const SizedBox(height: 16),

                  // Receiver Information Card with Address
                  if (order.receiverName != null) _buildReceiverInfoCard(order),
                  if (order.receiverName != null) const SizedBox(height: 16),

                  // Timeline Card
                  _buildTimelineCard(order),
                  const SizedBox(height: 16),

                  // Additional Information Card
                  _buildAdditionalInfoCard(order),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderStatusCard(CompletedOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (order.pickupNumber != null)
                    Text(
                      'Pickup: ${order.pickupNumber}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    SizedBox(width: 6),
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
          if (order.carrierTrackingNo != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
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
                      Icons.confirmation_number,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tracking Number',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.carrierTrackingNo!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSenderInfoCard(CompletedOrder order) {
    // Debug print to check values
    print('Sender Address: ${order.senderAddress}');
    print('Sender Landmark: ${order.senderLandmark}');
    print('Sender District: ${order.senderDistrict}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Sender Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRowWithIcon(
                  icon: Icons.person_outline,
                  iconColor: Colors.blue,
                  label: 'Name',
                  value: order.senderName?.toUpperCase() ?? 'Not Available',
                ),
                const SizedBox(height: 12),
                _buildInfoRowWithIcon(
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  label: 'Phone',
                  value: order.senderPhone,
                ),
                if (order.senderAddress != null &&
                    order.senderAddress!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRowWithIcon(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    label: 'Address',
                    value: order.senderAddress!,
                    isMultiLine: true,
                  ),
                ],
                if (order.senderLandmark != null &&
                    order.senderLandmark!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRowWithIcon(
                    icon: Icons.place,
                    iconColor: Colors.orange,
                    label: 'Landmark',
                    value: order.senderLandmark!,
                  ),
                ],
                // Always show location if any field exists
                if ((order.senderDistrict != null &&
                        order.senderDistrict!.isNotEmpty) ||
                    (order.senderState != null &&
                        order.senderState!.isNotEmpty) ||
                    (order.senderCountry != null &&
                        order.senderCountry!.isNotEmpty) ||
                    (order.senderZipCode != null &&
                        order.senderZipCode!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  _buildLocationRow(
                    district: order.senderDistrict,
                    state: order.senderState,
                    country: order.senderCountry,
                    zipCode: order.senderZipCode,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverInfoCard(CompletedOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Receiver Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRowWithIcon(
                  icon: Icons.person_outline,
                  iconColor: Colors.blue,
                  label: 'Name',
                  value: order.receiverName?.toUpperCase() ?? 'Not Available',
                ),
                if (order.receiverPhone != null &&
                    order.receiverPhone!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRowWithIcon(
                    icon: Icons.phone,
                    iconColor: Colors.green,
                    label: 'Phone',
                    value: order.receiverPhone!,
                  ),
                ],
                if (order.receiverAddress != null &&
                    order.receiverAddress!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRowWithIcon(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    label: 'Address',
                    value: order.receiverAddress!,
                    isMultiLine: true,
                  ),
                ],
                if (order.receiverLandmark != null &&
                    order.receiverLandmark!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRowWithIcon(
                    icon: Icons.place,
                    iconColor: Colors.orange,
                    label: 'Landmark',
                    value: order.receiverLandmark!,
                  ),
                ],
                if ((order.receiverDistrict != null &&
                        order.receiverDistrict!.isNotEmpty) ||
                    (order.receiverState != null &&
                        order.receiverState!.isNotEmpty) ||
                    (order.receiverCountry != null &&
                        order.receiverCountry!.isNotEmpty) ||
                    (order.receiverZipCode != null &&
                        order.receiverZipCode!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  _buildLocationRow(
                    district: order.receiverDistrict,
                    state: order.receiverState,
                    country: order.receiverCountry,
                    zipCode: order.receiverZipCode,
                    isReceiver: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: isMultiLine ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    String? district,
    String? state,
    String? country,
    String? zipCode,
    bool isReceiver = false,
  }) {
    List<String> locationParts = [];
    if (district != null && district.isNotEmpty) locationParts.add(district);
    if (state != null && state.isNotEmpty) locationParts.add(state);
    if (country != null && country.isNotEmpty) locationParts.add(country);
    if (zipCode != null && zipCode.isNotEmpty) locationParts.add(zipCode);

    String location = locationParts.join(', ');

    if (location.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.map, color: Colors.purple, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(CompletedOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTimelineItem(
            icon: Icons.create,
            iconColor: Colors.blue,
            title: 'Order Created',
            date: order.createdAt,
            isFirst: true,
          ),

          _buildTimelineItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.orange,
            title: 'Picked Up',
            date: order.pickedAt,
            subtitle: order.pickedAt != null
                ? 'Package picked from sender'
                : 'Not picked yet',
          ),

          _buildTimelineItem(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Delivered',
            date: order.deliveredAt,
            subtitle: order.deliveredAt != null
                ? 'Successfully delivered to receiver'
                : 'Not delivered yet',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    DateTime? date,
    String? subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatFullDateTime(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
              SizedBox(height: isLast ? 0 : 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoCard(CompletedOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Order ID', '#${order.id}'),
          if (order.pickupNumber != null)
            _buildInfoRow('Pickup Number', order.pickupNumber!),
          if (order.carrierTrackingNo != null)
            _buildInfoRow('Tracking Number', order.carrierTrackingNo!),
          _buildInfoRow('Status', 'Delivered', isStatus: true),
          if (order.latitude != null && order.longitude != null)
            _buildInfoRow(
              'Coordinates',
              '${order.latitude}, ${order.longitude}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        // spacing: 20,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label :",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
