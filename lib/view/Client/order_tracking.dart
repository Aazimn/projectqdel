import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ApiService apiService = ApiService();
  final Logger logger = Logger();

  Map<String, dynamic>? _orderDetails;
  Map<dynamic, dynamic>? _carrierLocation;
  bool _isLoading = true;
  bool _isLocationLoading = false;
  String _currentStatus = "unknown";
  int? _pickupCarrierId; // MISSING: This variable was missing
  Timer? _locationTimer; // MISSING: This timer was missing

  // Status flow for the horizontal timeline
  final List<Map<String, dynamic>> _statusFlow = [
    {"key": "pending", "label": "Order\nPlaced", "icon": Icons.receipt},
    {"key": "accepted", "label": "Accepted", "icon": Icons.check_circle},
    {
      "key": "arrived",
      "label": "Arrived at\nPickup",
      "icon": Icons.location_on,
    },
    {"key": "picked_up", "label": "Picked Up", "icon": Icons.inventory},
    {"key": "in_transit", "label": "In Transit", "icon": Icons.local_shipping},
    {
      "key": "arrived_at_drop",
      "label": "Arrived at\nDrop",
      "icon": Icons.location_pin,
    },
    {
      "key": "delivered",
      "label": "Delivered",
      "icon": Icons.check_circle_outline,
    },
  ];

  String _resolveOrderStatus(Map<String, dynamic> order) {
    final shipment = order["shipment_status"];
    if (shipment == null) return "pending";

    final status = shipment["status"]?.toString().toLowerCase() ?? "pending";
    final trackingNo = shipment["carrier_tracking_no"];

    if (status == "pending" &&
        (trackingNo == null || trackingNo.toString().isEmpty)) {
      return "searching";
    }

    return status;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _debugCheckAllSavedIds();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _debugCheckAllSavedIds() async {
    logger.i("🔍 DEBUG: Checking all saved pickup_carrier_ids");

    int? globalId = await ApiService.getPickupCarrierId();
    logger.i("📌 Global pickup_carrier_id: $globalId");

    int? orderId = await ApiService.getPickupCarrierIdForOrder(widget.pickupId);
    logger.i("📌 pickup_carrier_id for order ${widget.pickupId}: $orderId");
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    logger.i(
      "📌 All SharedPreferences keys: ${keys.where((key) => key.contains('carrier') || key.contains('order'))}",
    );
  }

  Future<void> _initializeData() async {
    setState(() {
      _orderDetails = widget.orderData;
      _currentStatus = _resolveOrderStatus(widget.orderData);
    });

    logger.i("🔍 Looking for pickup_carrier_id for order ${widget.pickupId}");
    _pickupCarrierId = _extractPickupCarrierIdFromOrder(widget.orderData);

    if (_pickupCarrierId != null) {
      logger.i("✅ Found pickup_carrier_id $_pickupCarrierId from order data");
      await _fetchCarrierLocation();
      _startLiveLocationTracking();
    } else {
      logger.w(
        "⚠️ No pickup_carrier_id found in order data for order ${widget.pickupId}",
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  int? _extractPickupCarrierIdFromOrder(Map<String, dynamic> order) {
    if (order['shipment_status'] != null &&
        order['shipment_status']['pickup_carrier_id'] != null) {
      return order['shipment_status']['pickup_carrier_id'];
    }
    if (order['pickup_carrier_id'] != null) {
      return order['pickup_carrier_id'];
    }

    return null;
  }

  void _startLiveLocationTracking() {
    if (_pickupCarrierId == null) return;

    _fetchCarrierLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _pickupCarrierId != null) {
        _fetchCarrierLocation(isAutoRefresh: true);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchCarrierLocation({bool isAutoRefresh = false}) async {
    if (_pickupCarrierId == null) {
      logger.w("Cannot fetch location: _pickupCarrierId is null");
      return;
    }

    if (!isAutoRefresh) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    try {
      final response = await apiService.getCarrierLiveLocation(
        id: _pickupCarrierId!,
      );

      if (mounted) {
        if (response != null && response['success'] == true) {
          final locationData = response['data'];

          double? latitude;
          double? longitude;

          if (locationData['latitude'] is String) {
            latitude = double.tryParse(locationData['latitude']);
          } else if (locationData['latitude'] is double) {
            latitude = locationData['latitude'];
          } else if (locationData['latitude'] is int) {
            latitude = (locationData['latitude'] as int).toDouble();
          }

          if (locationData['longitude'] is String) {
            longitude = double.tryParse(locationData['longitude']);
          } else if (locationData['longitude'] is double) {
            longitude = locationData['longitude'];
          } else if (locationData['longitude'] is int) {
            longitude = (locationData['longitude'] as int).toDouble();
          }
          final cleanData = {
            ...locationData,
            'latitude': latitude,
            'longitude': longitude,
          };

          setState(() {
            _carrierLocation = cleanData;
          });

          if (!isAutoRefresh) {
            logger.i("✅ Initial carrier location fetched: $_carrierLocation");
          } else {
            logger.i("🔄 Location updated: $latitude, $longitude");
          }
        } else {
          if (!isAutoRefresh) {
            logger.e(
              "❌ Failed to fetch carrier location: ${response?['error']}",
            );
          }
        }
      }
    } catch (e) {
      if (!isAutoRefresh) {
        logger.e("Error fetching carrier location: $e");
      }
    } finally {
      if (mounted && !isAutoRefresh) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _openMapWithCarrierLocation() {
    if (_carrierLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Carrier location not available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("📍 Opening map with location:");
    print("   Full location data: $_carrierLocation");

    final lat = _carrierLocation!['latitude'];
    final lng = _carrierLocation!['longitude'];

    print("   Latitude: $lat (${lat.runtimeType})");
    print("   Longitude: $lng (${lng.runtimeType})");

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid carrier location coordinates"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    print("   URL: $url");
    _launchUrl(url);
  }

  void _openMapWithDestination() {
    final receiverAddress = _orderDetails?['receiver_address'];
    if (receiverAddress == null) return;

    final double? lat = receiverAddress['latitude'];
    final double? lng = receiverAddress['longitude'];

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Destination coordinates not available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    _launchUrl(url);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }

  int _getCurrentStatusIndex() {
    switch (_currentStatus) {
      case "searching":
        return 0;
      case "pending":
        return 1;
      case "arrived":
        return 2;
      case "picked_up":
        return 3;
      case "in_transit":
        return 4;
      case "arrived_at_drop":
        return 5;
      case "delivered":
        return 6;
      default:
        return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "searching":
        return Colors.orange;
      case "pending":
        return Colors.teal;
      case "arrived":
        return Colors.blue;
      case "picked_up":
        return Colors.indigo;
      case "in_transit":
        return Colors.blueAccent;
      case "arrived_at_drop":
        return Colors.green;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case "searching":
        return "Searching for delivery partner";
      case "pending":
        return "Carrier accepted and heading to pickup";
      case "arrived":
        return "Carrier arrived at pickup location";
      case "picked_up":
        return "Order picked up and on the way";
      case "in_transit":
        return "Order is in transit to destination";
      case "arrived_at_drop":
        return "Carrier arrived at drop location";
      case "delivered":
        return "Order delivered successfully";
      default:
        return "Processing your order";
    }
  }

  String _getLastUpdatedText() {
    if (_carrierLocation == null || _carrierLocation!['last_updated'] == null) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(_carrierLocation!['last_updated']);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 5) {
        return 'Live now';
      } else if (difference.inMinutes < 1) {
        return '${difference.inSeconds} seconds ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return _carrierLocation!['last_updated'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: ColorConstants.red,
          title: const Text(
            "Tracking Order",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statusColor = _getStatusColor(_currentStatus);
    final currentStatusIndex = _getCurrentStatusIndex();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: const Text("Track Order", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order #${_orderDetails?['pickup_no'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _orderDetails?['product_details']?['name'] ??
                                    'Product',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  _currentStatus.toUpperCase().replaceAll(
                                    '_',
                                    ' ',
                                  ),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_statusFlow.length, (index) {
                    final isCompleted = index <= currentStatusIndex;
                    final isCurrent = index == currentStatusIndex;

                    return Row(
                      children: [
                        if (index > 0)
                          Container(
                            width: 40,
                            height: 2,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? statusColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? statusColor
                                    : Colors.grey.shade200,
                                border: isCurrent
                                    ? Border.all(color: statusColor, width: 3)
                                    : null,
                              ),
                              child: Icon(
                                _statusFlow[index]['icon'],
                                color: isCompleted
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _statusFlow[index]['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCompleted
                                    ? statusColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            Container(
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
                    child: Icon(
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
                          "Current Status",
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
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: ColorConstants.red),
                          SizedBox(width: 8),
                          Text(
                            "Live Tracking",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_carrierLocation != null)
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
                                "LIVE",
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
                  const SizedBox(height: 16),

                  if (_isLocationLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_carrierLocation != null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Delivery Partner Location",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.gps_fixed,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${_carrierLocation!['latitude']?.toStringAsFixed(6) ?? 'N/A'}, ${_carrierLocation!['longitude']?.toStringAsFixed(6) ?? 'N/A'}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Updated: ${_getLastUpdatedText()}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
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
                              child: ElevatedButton.icon(
                                onPressed: _openMapWithCarrierLocation,
                                icon: const Icon(Icons.place),
                                label: const Text("See Location"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Live location not available yet",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchCarrierLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Refresh"),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
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
                        "Order Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    "Product",
                    _orderDetails?['product_details']?['name'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    "Weight",
                    "${_orderDetails?['product_details']?['actual_weight'] ?? 'N/A'} kg",
                  ),
                  _buildDetailRow(
                    "Volume",
                    "${_orderDetails?['product_details']?['volume'] ?? 'N/A'}",
                  ),

                  const Divider(height: 24),

                  const Text(
                    "Pickup Address",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _orderDetails?['sender_address']?['address'] ?? 'N/A',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    "${_orderDetails?['sender_address']?['district'] ?? ''}, ${_orderDetails?['sender_address']?['state'] ?? ''}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),

                  const Divider(height: 24),

                  const Text(
                    "Delivery Address",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _orderDetails?['receiver_address']?['address_text'] ??
                        'N/A',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    "${_orderDetails?['receiver_address']?['district'] ?? ''}, ${_orderDetails?['receiver_address']?['state'] ?? ''}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _openMapWithDestination,
                    icon: const Icon(Icons.map),
                    label: const Text("View Destination on Map"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: _carrierLocation != null
          ? FloatingActionButton(
              onPressed: _fetchCarrierLocation,
              backgroundColor: ColorConstants.red,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  // void _openMapWithRouteToCarrier() {
  //   if (_carrierLocation == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Carrier location not available"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   final lat = _carrierLocation!['latitude'];
  //   final lng = _carrierLocation!['longitude'];

  //   if (lat == null || lng == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Invalid carrier location coordinates"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //   // Open Google Maps with directions
  //   final url =
  //       "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
  //   _launchUrl(url);
  // }

  Widget _buildDetailRow(String label, String value) {
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

  // String _formatTimestamp(String? timestamp) {
  //   if (timestamp == null) return 'N/A';
  //   try {
  //     final date = DateTime.parse(timestamp);
  //     final now = DateTime.now();
  //     final difference = now.difference(date);

  //     if (difference.inMinutes < 1) {
  //       return 'Just now';
  //     } else if (difference.inMinutes < 60) {
  //       return '${difference.inMinutes} min ago';
  //     } else if (difference.inHours < 24) {
  //       return '${difference.inHours} hours ago';
  //     } else {
  //       return '${difference.inDays} days ago';
  //     }
  //   } catch (e) {
  //     return timestamp;
  //   }
  // }
}
