import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:logger/logger.dart';


class OrderTrackingScreen extends StatefulWidget {
  final int pickupId;
  final Map<String, dynamic> orderData;

  const OrderTrackingScreen({
    super.key,
    required this.pickupId,
    required this.orderData,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();
  final MapController _mapController = MapController();

  Map<String, dynamic>? _orderDetails;
  LatLng? _carrierLatLng;
  Map<dynamic, dynamic>? _carrierLocationRaw;

  bool _isLoading = true;
  bool _mapReady = false;
  String _currentStatus = 'unknown';
  int? _pickupCarrierId;

  Timer? _locationTimer;


  final List<Map<String, dynamic>> _statusFlow = [
    {'key': 'pending', 'label': 'Order\nPlaced', 'icon': Icons.receipt},
    {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
    {
      'key': 'arrived',
      'label': 'Arrived at\nPickup',
      'icon': Icons.location_on,
    },
    {'key': 'picked_up', 'label': 'Picked Up', 'icon': Icons.inventory},
    {'key': 'in_transit', 'label': 'In Transit', 'icon': Icons.local_shipping},
    {
      'key': 'arrived_at_drop',
      'label': 'Arrived at\nDrop',
      'icon': Icons.location_pin,
    },
    {
      'key': 'delivered',
      'label': 'Delivered',
      'icon': Icons.check_circle_outline,
    },
  ];


  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }


  Future<void> _initializeData() async {
    setState(() {
      _orderDetails = widget.orderData;
      _currentStatus = _resolveOrderStatus(widget.orderData);
    });

    _pickupCarrierId = _extractPickupCarrierId(widget.orderData);

    if (_pickupCarrierId == null) {
      _pickupCarrierId = await ApiService.getPickupCarrierIdForOrder(
        widget.pickupId,
      );
      _logger.w(
        '⚠️ pickup_carrier_id not in orderData — loaded from prefs: $_pickupCarrierId',
      );
    }
    if (_pickupCarrierId == null) {
      _logger.w('⚠️ Still no pickup_carrier_id — fetching order from API');
      await _refreshOrderFromApi();
    }

    if (_pickupCarrierId != null) {
      _logger.i('✅ pickup_carrier_id = $_pickupCarrierId');
      await _fetchCarrierLocation(); 
      _startLiveTracking();
    } else {
      _logger.e(
        '❌ Could not resolve pickup_carrier_id for order ${widget.pickupId}',
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshOrderFromApi() async {
    try {
      final order = await _apiService.fetchOrderById(widget.pickupId);
      if (order != null) {
        final shipment = order.toJson()['shipment_status'];
        if (shipment != null && shipment['pickup_carrier_id'] != null) {
          _pickupCarrierId = shipment['pickup_carrier_id'];
        }
      }
    } catch (e) {
      _logger.e('Error fetching order from API: $e');
    }
  }

  int? _extractPickupCarrierId(Map<String, dynamic> order) {
    final shipment = order['shipment_status'];
    if (shipment is Map && shipment['pickup_carrier_id'] != null) {
      return _toInt(shipment['pickup_carrier_id']);
    }
    if (order['pickup_carrier_id'] != null) {
      return _toInt(order['pickup_carrier_id']);
    }
    final carrier = order['carrier'];
    if (carrier is Map && carrier['id'] != null) {
      return _toInt(carrier['id']);
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _startLiveTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _pickupCarrierId != null) {
        _fetchCarrierLocation(silent: true);
      }
    });
  }

Future<void> _fetchCarrierLocation({bool silent = false}) async {
  if (_pickupCarrierId == null) return;

  try {
    final response = await _apiService.getCarrierLiveLocation(
      id: _pickupCarrierId!,
    );

    _logger.i("📥 API RESPONSE = $response");

    if (!mounted) return;

    final isSuccess =
        response != null &&
        (response['success'] == true || response['status'] == 'success');

    if (!isSuccess) {
      if (!silent) {
        _logger.e("❌ getCarrierLiveLocation failed — response: $response");
      }
      return;
    }

    final data = Map<String, dynamic>.from(response['data']['data']);

    _logger.i("📦 Parsed location payload = $data");

    final lat = _parseDouble(data['latitude']);
    final lng = _parseDouble(data['longitude']);

    _logger.i("📍 Parsed coords lat=$lat lng=$lng");

    if (lat == null || lng == null) {
      _logger.e("❌ Invalid coordinates");
      return;
    }

    final newLatLng = LatLng(lat, lng);

    if (!mounted) return;

    setState(() {
      _carrierLocationRaw = data;
      _carrierLatLng = newLatLng;
    });

    _logger.i("📍 UI updated with location: $_carrierLatLng");

    if (_mapReady) {
      try {
        _mapController.move(newLatLng, _mapController.camera.zoom);
      } catch (_) {}
    }

    if (!silent) {
      _logger.i('📍 Carrier location: $lat, $lng');
    }
  } catch (e) {
    if (!silent) {
      _logger.e('Error fetching carrier location: $e');
    }
  }
}    
  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String _resolveOrderStatus(Map<String, dynamic> order) {
    final shipment = order['shipment_status'];
    if (shipment == null) return 'pending';
    final status = shipment['status']?.toString().toLowerCase() ?? 'pending';
    final trackingNo = shipment['carrier_tracking_no'];
    if (status == 'pending' &&
        (trackingNo == null || trackingNo.toString().isEmpty)) {
      return 'searching';
    }
    return status;
  }

  int _getCurrentStatusIndex() {
    const order = [
      'searching',
      'pending',
      'arrived',
      'picked_up',
      'in_transit',
      'arrived_at_drop',
      'delivered',
    ];
    final idx = order.indexOf(_currentStatus);
    return idx < 0 ? 0 : idx;
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'searching':
        return Colors.orange;
      case 'pending':
        return Colors.teal;
      case 'arrived':
        return Colors.blue;
      case 'picked_up':
        return Colors.indigo;
      case 'in_transit':
        return Colors.blueAccent;
      case 'arrived_at_drop':
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case 'searching':
        return 'Searching for delivery partner';
      case 'pending':
        return 'Carrier accepted and heading to pickup';
      case 'arrived':
        return 'Carrier arrived at pickup location';
      case 'picked_up':
        return 'Order picked up and on the way';
      case 'in_transit':
        return 'Order is in transit to destination';
      case 'arrived_at_drop':
        return 'Carrier arrived at drop location';
      case 'delivered':
        return 'Order delivered successfully';
      default:
        return 'Processing your order';
    }
  }

  String _getLastUpdatedText() {
    final raw = _carrierLocationRaw?['updated_at'];
    if (raw == null) return 'N/A';
    try {
      final date = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 5) return 'Live now';
      if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return raw.toString();
    }
  }


  void _openCarrierInGoogleMaps() {
    if (_carrierLatLng == null) {
      _showSnack('Carrier location not available', isError: true);
      return;
    }
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_carrierLatLng!.latitude},${_carrierLatLng!.longitude}';
    _launchUrl(url);
  }

  void _openDestinationInGoogleMaps() {
    final lat = _parseDouble(_orderDetails?['receiver_address']?['latitude']);
    final lng = _parseDouble(_orderDetails?['receiver_address']?['longitude']);
    if (lat == null || lng == null) {
      _showSnack('Destination coordinates not available', isError: true);
      return;
    }
    _launchUrl('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statusColor = _getStatusColor();
    final currentIndex = _getCurrentStatusIndex();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      floatingActionButton: _carrierLatLng != null
          ? FloatingActionButton(
              onPressed: () => _fetchCarrierLocation(),
              backgroundColor: ColorConstants.red,
              tooltip: 'Refresh location',
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusStepper(statusColor, currentIndex),
            _buildStatusBanner(statusColor),
            _buildLiveMapCard(statusColor),
            _buildOrderDetailsCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: ColorConstants.red,
    title: const Text('Track Order', style: TextStyle(color: Colors.white)),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
  );


  Widget _buildHeader() {
    final statusColor = _getStatusColor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${_orderDetails?['pickup_no'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _orderDetails?['product_details']?['name'] ?? 'Product',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              _currentStatus.toUpperCase().replaceAll('_', ' '),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(Color statusColor, int currentIndex) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_statusFlow.length, (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            return Row(
              children: [
                if (index > 0)
                  Container(
                    width: 40,
                    height: 2,
                    color: isCompleted ? statusColor : Colors.grey.shade300,
                  ),
                Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? statusColor : Colors.grey.shade200,
                        border: isCurrent
                            ? Border.all(color: statusColor, width: 3)
                            : null,
                      ),
                      child: Icon(
                        _statusFlow[index]['icon'] as IconData,
                        color: isCompleted
                            ? Colors.white
                            : Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusFlow[index]['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompleted ? statusColor : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }


  Widget _buildStatusBanner(Color statusColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLiveMapCard(Color statusColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: ColorConstants.red),
                    SizedBox(width: 8),
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_carrierLatLng != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 150,
            child: _carrierLatLng == null
                ? const Center(child: CircularProgressIndicator())
                : _buildMap(),
          ),

          if (_carrierLatLng != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated: ${_getLastUpdatedText()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_carrierLatLng!.latitude.toStringAsFixed(5)}, ${_carrierLatLng!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openCarrierInGoogleMaps,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final destLat = _parseDouble(
      _orderDetails?['receiver_address']?['latitude'],
    );
    final destLng = _parseDouble(
      _orderDetails?['receiver_address']?['longitude'],
    );
    final destLatLng = (destLat != null && destLng != null)
        ? LatLng(destLat, destLng)
        : null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.zero,
        bottom: Radius.zero,
      ),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _carrierLatLng!,
            initialZoom: 15,
            onMapReady: () => setState(() => _mapReady = true),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.projectqdel.app',
            ),

            MarkerLayer(
              markers: [
           
                Marker(
                  point: _carrierLatLng!,
                  width: 50,
                  height: 50,
                  child: _CarrierMarker(color: ColorConstants.red),
                ),

                if (destLatLng != null)
                  Marker(
                    point: destLatLng,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt, color: ColorConstants.red),
              SizedBox(width: 8),
              Text(
                'Order Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(
            'Product',
            _orderDetails?['product_details']?['name'] ?? 'N/A',
          ),
          _detailRow(
            'Weight',
            '${_orderDetails?['product_details']?['actual_weight'] ?? 'N/A'} kg',
          ),
          _detailRow(
            'Volume',
            '${_orderDetails?['product_details']?['volume'] ?? 'N/A'}',
          ),
          const Divider(height: 24),
          const Text(
            'Pickup Address',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _orderDetails?['sender_address']?['address'] ?? 'N/A',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            '${_orderDetails?['sender_address']?['district'] ?? ''}, ${_orderDetails?['sender_address']?['state'] ?? ''}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const Divider(height: 24),
          const Text(
            'Delivery Address',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _orderDetails?['receiver_address']?['address_text'] ?? 'N/A',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            '${_orderDetails?['receiver_address']?['district'] ?? ''}, ${_orderDetails?['receiver_address']?['state'] ?? ''}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openDestinationInGoogleMaps,
            icon: const Icon(Icons.map),
            label: const Text('View Destination on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}


class _CarrierMarker extends StatefulWidget {
  final Color color;
  const _CarrierMarker({required this.color});

  @override
  State<_CarrierMarker> createState() => _CarrierMarkerState();
}

class _CarrierMarkerState extends State<_CarrierMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
      ),
    );
  }
}
