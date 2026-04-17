import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/web.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/delivery_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/model/order_model.dart';
import 'package:projectqdel/view/Carrier/accepted_screen.dart';

class CarrierMapScreen extends StatefulWidget {
  final DeliveryMode? selectedDeliveryMode;

  const CarrierMapScreen({super.key, this.selectedDeliveryMode});
  @override
  State<CarrierMapScreen> createState() => _CarrierMapScreenState();
}

class _CarrierMapScreenState extends State<CarrierMapScreen> {
  bool isLocationEnabled = false;
  bool isCheckingLocation = true;
  Logger logger = Logger();
  LatLng? carrierLocation;
  Future<List<OrderModel>>? ordersFuture;
  static const double radiusMeters = 5000;
  StreamSubscription<Position>? _locationStream;
  int? selectedShopDropId;

  Future<void> _startLiveLocation() async {
    _locationStream?.cancel();

    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50,
          ),
        ).listen((position) async {
          setState(() {
            carrierLocation = LatLng(position.latitude, position.longitude);
          });

          try {
            int? pickupCarrierId = await ApiService.getPickupCarrierId();

            if (pickupCarrierId == null) {
              logger.w("⚠️ pickupCarrierId not available yet");
              return;
            }

            await ApiService().updateCarrierLocation(
              pickupCarrierId: pickupCarrierId,
              latitude: position.latitude,
              longitude: position.longitude,
            );

            logger.i(
              "📍 Location Updated -> ${position.latitude}, ${position.longitude} | ID: $pickupCarrierId",
            );
          } catch (e) {
            logger.e("❌ Live location update error: $e");
          }
        });
  }

  bool _isWithinRadius(OrderModel order) {
    if (carrierLocation == null) return false;

    final lat = order.senderAddress?.latitude;
    final lng = order.senderAddress?.longitude;

    if (lat == null || lng == null) return false;

    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      lat,
      lng,
    );
    return distance <= radiusMeters;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocationAndFetch();
  }

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetch();
  }

  Future<void> _checkLocationAndFetch() async {
    setState(() {
      isCheckingLocation = true;
    });

    final location = await ApiService().getCarrierCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      setState(() {
        isLocationEnabled = false;
        carrierLocation = null;
        ordersFuture = null;
        isCheckingLocation = false;
      });
    } else {
      setState(() {
        isLocationEnabled = true;
        carrierLocation = location;

        if (widget.selectedDeliveryMode != null) {
          debugPrint(
            "🔍 Filtering orders by delivery mode: ${widget.selectedDeliveryMode!.name} (ID: ${widget.selectedDeliveryMode!.id})",
          );
          ordersFuture = ApiService().getAllOrders(
            deliveryModeId: widget.selectedDeliveryMode!.id,
          );
        } else {
          ordersFuture = ApiService().getAllOrders();
        }

        isCheckingLocation = false;
      });
      _startLiveLocation();
    }
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Exit Confirmation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Exit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ColorConstants.red,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pickup Orders",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              if (widget.selectedDeliveryMode != null)
                Text(
                  widget.selectedDeliveryMode!.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: isCheckingLocation
            ? const Center(child: CircularProgressIndicator())
            : (!isLocationEnabled ? _locationOffUI() : _mapWithOrders()),
      ),
    );
  }

  Widget _locationOffUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Location access is required to view pickup orders.\nPlease enable GPS.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                setState(() => isCheckingLocation = true);

                final enabled = await _enableLocation();

                if (enabled) {
                  await _checkLocationAndFetch();
                } else {
                  setState(() => isCheckingLocation = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
              ),
              child: const Text(
                "Enable Location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapWithOrders() {
    return FutureBuilder<List<OrderModel>>(
      future: ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error loading orders: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final orders = snapshot.data ?? [];
        print("Total orders received: ${orders.length}");

        final validOrders = orders
            .where(_hasValidLocation)
            .where(_isWithinRadius)
            .toList();
        print("📦 Orders inside 5 km radius: ${validOrders.length}");
        print("Orders with valid locations: ${validOrders.length}");
        print(
          "📍 Carrier location: ${carrierLocation?.latitude}, ${carrierLocation?.longitude}",
        );

        for (var i = 0; i < validOrders.length; i++) {
          final order = validOrders[i];
          print("🔍 Valid Order $i - ID: ${order.id}");
          print("   Lat: ${order.senderAddress!.latitude}");
          print("   Lng: ${order.senderAddress!.longitude}");
          print("   Address: ${order.senderAddress!.address}");
        }
        if (validOrders.length > 1) {
          for (var i = 0; i < validOrders.length; i++) {
            for (var j = i + 1; j < validOrders.length; j++) {
              final lat1 = validOrders[i].senderAddress!.latitude!;
              final lng1 = validOrders[i].senderAddress!.longitude!;
              final lat2 = validOrders[j].senderAddress!.latitude!;
              final lng2 = validOrders[j].senderAddress!.longitude!;

              final distance = (lat1 - lat2).abs() + (lng1 - lng2).abs();
              print(
                "📏 Distance between order ${validOrders[i].id} and ${validOrders[j].id}: $distance",
              );

              if (distance < 0.0001) {
                print(
                  "⚠️ Orders are VERY close together - markers might be overlapping!",
                );
              }
            }
          }
        }

        final markers = <Marker>[
          Marker(
            point: carrierLocation!,
            width: 50,
            height: 50,
            child: Lottie.asset(
              "assets/lottie_assets/carrier_location.json",
              repeat: true,
              animate: true,
              fit: BoxFit.contain,
            ),
          ),
        ];
        for (var i = 0; i < validOrders.length; i++) {
          final order = validOrders[i];
          markers.add(
            Marker(
              key: Key('order_${order.id}'),
              point: LatLng(
                order.senderAddress!.latitude!,
                order.senderAddress!.longitude!,
              ),
              width: 80,
              height: 50,
              child: GestureDetector(
                onTap: () => _showOrderDetails(order),
                child: Container(
                  child: Lottie.asset(
                    "assets/lottie_assets/location.json",
                    repeat: true,
                    animate: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        }

        print("🎯 Total markers to display: ${markers.length}");

        if (validOrders.isNotEmpty && carrierLocation != null) {
          final allPoints = [
            carrierLocation!,
            ...validOrders.map(
              (o) => LatLng(
                o.senderAddress!.latitude!,
                o.senderAddress!.longitude!,
              ),
            ),
          ];

          double minLat = allPoints
              .map((p) => p.latitude)
              .reduce((a, b) => a < b ? a : b);
          double maxLat = allPoints
              .map((p) => p.latitude)
              .reduce((a, b) => a > b ? a : b);
          double minLng = allPoints
              .map((p) => p.longitude)
              .reduce((a, b) => a < b ? a : b);
          double maxLng = allPoints
              .map((p) => p.longitude)
              .reduce((a, b) => a > b ? a : b);

          print(
            "📍 Map bounds - Lat: $minLat to $maxLat, Lng: $minLng to $maxLng",
          );
          final centerLat = (minLat + maxLat) / 2;
          final centerLng = (minLng + maxLng) / 2;
          final latSpread = (maxLat - minLat).abs();
          final lngSpread = (maxLng - minLng).abs();
          final maxSpread = latSpread > lngSpread ? latSpread : lngSpread;

          double zoomLevel;
          if (maxSpread > 0.1)
            zoomLevel = 11;
          else if (maxSpread > 0.05)
            zoomLevel = 12;
          else if (maxSpread > 0.01)
            zoomLevel = 13;
          else if (maxSpread > 0.005)
            zoomLevel = 14;
          else
            zoomLevel = 15;

          print(
            "📍 Map center: ($centerLat, $centerLng), Zoom: $zoomLevel, Spread: $maxSpread",
          );

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: zoomLevel,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.projectqdel',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: carrierLocation!,
                    radius: radiusMeters,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(markers: markers),
            ],
          );
        }
        return FlutterMap(
          options: MapOptions(initialCenter: carrierLocation!, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.projectqdel',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  bool _hasValidLocation(OrderModel order) {
    if (order.senderAddress == null) {
      print("Order ${order.id}: No senderAddress");
      return false;
    }
    final lat = order.senderAddress?.latitude;
    final lng = order.senderAddress?.longitude;
    if (lat == null || lng == null) {
      print("Order ${order.id}: Missing lat or lng");
      return false;
    }

    print("✅ Order ${order.id}: Valid location - ($lat, $lng)");
    return true;
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isAcceptingLocally = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                 
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.local_shipping,
                                color: Colors.red.shade700,
                                size: 24,
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Product Details",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          "Weight",
                          order.productDetails?.actualWeight.toString() ??
                              "Not specified",
                          "kg",
                          Icons.fitness_center,
                        ),
                        _buildDetailRow(
                          "Volume",
                          order.productDetails?.volume ?? "Not specified",
                          "cm³",
                          Icons.crop_free,
                        ),
                        _buildDetailRow(
                          "Description",
                          order.productDetails?.description ?? "No description",
                          "",
                          Icons.description,
                          isLongText: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

           
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 18,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Delivery Journey",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTimelineItem(
                          isFirst: true,
                          isLast: false,
                          icon: Icons.location_on,
                          iconColor: Colors.red.shade700,
                          title: "PICKUP LOCATION",
                          name:
                              order.senderAddress?.senderName.toUpperCase() ??
                              "Sender",
                          address:
                              order.senderAddress?.address ??
                              "Pickup address not available",
                        ),
                        _buildTimelineItem(
                          isFirst: false,
                          isLast: true,
                          icon: Icons.location_on,
                          iconColor: Colors.green,
                          title: "DELIVERY LOCATION",
                          name:
                              order.receiverAddress?.receiverName
                                  .toUpperCase() ??
                              "Receiver",
                          address: order.receiverAddress != null
                              ? "${order.receiverAddress!.address}, ${order.receiverAddress!.district}, ${order.receiverAddress!.state}, ${order.receiverAddress!.country}"
                              : "Delivery address not available",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

        
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    child: Row(
                      children: [
                       
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                    
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isAcceptingLocally
                                ? null
                                : () async {
                                    setModalState(() {
                                      isAcceptingLocally = true;
                                    });
                                    await _acceptOrder(order);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: isAcceptingLocally
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Accept Order",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    String? unit,
    IconData icon, {
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$value $unit".trim(),

                  style: TextStyle(
                    fontSize: isLongText ? 13 : 14,
                    fontWeight: isLongText
                        ? FontWeight.normal
                        : FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: isLongText ? 3 : 1,
                  overflow: isLongText ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required bool isFirst,
    required bool isLast,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              if (!isLast)
                Container(width: 2, height: 60, color: Colors.grey.shade300),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _enableLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      if (carrierLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Carrier location not available"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await ApiService.clearPickupCarrierId();

      final response = await ApiService().acceptOrder(
        pickupId: order.id,
        latitude: carrierLocation!.latitude,
        longitude: carrierLocation!.longitude,
      );

      if (!mounted) return;

      if (response != null) {
        Navigator.pop(context);

        await ApiService.saveActiveOrder(order.id);
        await ApiService.saveActiveOrderDetails(order);

        if (ApiService().lastAcceptedPickupCarrierId != null) {
          int pickupCarrierId = ApiService().lastAcceptedPickupCarrierId!;

          await ApiService.savePickupCarrierId(pickupCarrierId);
          debugPrint("✅ Saved global pickup_carrier_id: $pickupCarrierId");

          await ApiService.savePickupCarrierIdForOrder(
            order.id,
            pickupCarrierId,
          );
          debugPrint(
            "✅ Saved pickup_carrier_id $pickupCarrierId for order ${order.id}",
          );

          int? savedId = await ApiService.getPickupCarrierIdForOrder(order.id);
          debugPrint(
            "✅ Verified: pickup_carrier_id for order ${order.id} is $savedId",
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "✅ Saved ID $pickupCarrierId for Order ${order.id}",
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          debugPrint("⚠️ No pickup_carrier_id captured from response");
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AcceptedOrderScreen(
              orderId: order.id,
              order: order,
              selectedShopDropId: selectedShopDropId, 
            ),
          ),
        );

        setState(() {
          ordersFuture = ApiService().getAllOrders();
        });
      }
    } catch (e) {
      logger.e("Error accepting order: $e");
    }
  }
}
