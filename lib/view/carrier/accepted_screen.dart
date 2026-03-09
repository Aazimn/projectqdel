import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/model/order_model.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:slider_button/slider_button.dart';
import 'package:pinput/pinput.dart';
import 'package:logger/logger.dart';

class AcceptedOrderScreen extends StatefulWidget {
  final int orderId;
  final OrderModel? order;

  const AcceptedOrderScreen({super.key, required this.orderId, this.order});

  @override
  State<AcceptedOrderScreen> createState() => _AcceptedOrderScreenState();
}

class _AcceptedOrderScreenState extends State<AcceptedOrderScreen> {
  final ApiService apiService = ApiService();
  OrderModel? order;
  bool isLoading = true;
  bool isArrived = false;
  bool isSubmitting = false;
  bool isOtpSent = false;
  bool isVerifying = false;
  bool _isLoadingState = true;
  Logger logger = Logger();
  bool isPickupVerified = false; // New state to track if pickup is verified

  bool isDeliveryArrived = false;
  bool isDeliveryOtpSent = false;
  bool isDeliveryVerifying = false;
  bool isDeliveryVerified = false;

  final TextEditingController _otpController = TextEditingController();

  LatLng? carrierLocation;
  StreamSubscription<Position>? _locationStream;

  void _debugOrderData() {
    if (order != null) {
      print("🔍 Order ID: ${order!.id}");
      print("🔍 Pickup No: ${order!.pickupNo}");
      print("🔍 Product Details: ${order!.productDetails?.toJson()}");
      print("🔍 Sender Details: ${order!.senderDetails?.toJson()}");
      print("🔍 Sender Address: ${order!.senderAddress?.toJson()}");
      print("🔍 Receiver Details: ${order!.receiverDetails?.toJson()}");
      print("🔍 Receiver Address: ${order!.receiverAddress?.toJson()}");
    }
  }

  void _debugPickupCarrierId() async {
    int? pickupCarrierId = await ApiService.getPickupCarrierId();
    if (pickupCarrierId != null) {
      print("✅ Found pickup_carrier_id in SharedPreferences: $pickupCarrierId");
    } else {
      print("❌ No pickup_carrier_id found in SharedPreferences");
    }
  }

  Timer? _locationUpdateTimer;
  bool _isLocationUpdatesEnabled = false;

  void _startLocationUpdates() async {
    // Wait for order to be loaded
    if (order == null) {
      logger.w(
        "Cannot start location updates: order is null, will retry in 1 second",
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startLocationUpdates();
      });
      return;
    }

    // Only start if we have pickup_carrier_id and order is active
    int? pickupCarrierId = await ApiService.getPickupCarrierId();

    if (pickupCarrierId == null) {
      logger.w("Cannot start location updates: missing pickup_carrier_id");
      return;
    }

    // Don't start updates if order is completed
    if (isDeliveryVerified) {
      logger.i("Order completed, stopping location updates");
      return;
    }

    setState(() {
      _isLocationUpdatesEnabled = true;
    });

    logger.i(
      "🟢 Starting live location updates every 10 seconds for pickup_carrier_id: $pickupCarrierId",
    );

    // Cancel existing timer if any
    _locationUpdateTimer?.cancel();

    // Start new timer to send location every 10 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted || !_isLocationUpdatesEnabled) {
        timer.cancel();
        return;
      }

      // Stop if order is completed
      if (isDeliveryVerified) {
        logger.i("Order completed, stopping location updates");
        timer.cancel();
        return;
      }

      await _sendCurrentLocation();
    });
  }

  Future<void> _sendCurrentLocation() async {
    try {
      if (carrierLocation == null) {
        logger.w("Cannot send location: carrierLocation is null");
        return;
      }

      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) {
        logger.w("Cannot send location: pickup_carrier_id is null");
        return;
      }

      final response = await apiService.updateCarrierLocation(
        pickupCarrierId: pickupCarrierId,
        latitude: carrierLocation!.latitude,
        longitude: carrierLocation!.longitude,
      );

      if (response != null && response['success'] == true) {
        logger.i(
          "📍 Location sent successfully - Lat: ${carrierLocation!.latitude}, Lng: ${carrierLocation!.longitude}",
        );
      } else {
        logger.e("❌ Failed to send location: ${response?['error']}");
      }
    } catch (e) {
      logger.e("Error sending location: $e");
    }
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    setState(() {
      _isLocationUpdatesEnabled = false;
    });
    logger.i("🔴 Stopped live location updates");
  }

  @override
  void initState() {
    super.initState();
    print("📱 initState called - order from widget: ${widget.order?.id}");
    _loadSavedState();
    _startLiveLocation(); // This gets device location
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start sending location when screen is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });
  }

  @override
  void didUpdateWidget(covariant AcceptedOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart location updates if needed
    if (widget.order != oldWidget.order) {
      _stopLocationUpdates();
      _startLocationUpdates();
    }
  }

  // Update _markDelivered to stop updates when order completes
  Future<void> _markDelivered() async {
    setState(() => isSubmitting = true);

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        logger.e("❌ No pickup_carrier_id found!");
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isSubmitting = false);
        return;
      }

      final response = await apiService.markDelivered(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] != false) {
        setState(() {
          isDeliveryArrived = true;
          isSubmitting = false;
        });

        if (order != null) {
          await ApiService.saveDeliveryArrivalStatus(order!.id, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arrived at delivery location"),
            backgroundColor: Colors.green,
          ),
        );

        _showDeliveryOtpBottomSheet();
      } else {
        setState(() => isSubmitting = false);
        String errorMsg =
            response?['error'] ?? "Failed to mark delivery arrival";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      _showErrorSnackBar("Error: $e");
    }
  }

  // Update _verifyDeliveryOtp to stop updates when order is complete
  Future<void> _verifyDeliveryOtp(String otp) async {
    setState(() {
      isDeliveryVerifying = true;
    });

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isDeliveryVerifying = false);
        return;
      }

      final response = await apiService.verifyDeliveryOtp(
        pickupCarrierId: pickupCarrierId,
        otp: otp,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        if (order != null) {
          await ApiService.saveDeliveryVerifiedStatus(order!.id, true);
        }

        // Stop location updates before closing
        _stopLocationUpdates();

        Navigator.pop(context);

        if (order != null) {
          await ApiService.clearOrderStatus(order!.id);
        }
        await ApiService.clearActiveOrder();
        await ApiService.clearPickupCarrierId();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Delivery completed successfully! Thank you."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CarrierDashboard()),
          (route) => false,
        );
      } else {
        String errorMsg = response?['error'] ?? "Invalid OTP";
        _showErrorSnackBar(errorMsg);
        setState(() => isDeliveryVerifying = false);
      }
    } catch (e) {
      logger.e("Error verifying delivery OTP: $e");
      _showErrorSnackBar("Error verifying OTP: $e");
      setState(() => isDeliveryVerifying = false);
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _locationStream?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    // Load all saved states from SharedPreferences
    if (widget.order != null) {
      int orderId = widget.order!.id;

      // Load pickup arrival status
      bool? savedArrived = await ApiService.getArrivalStatus(orderId);
      if (savedArrived != null) {
        setState(() {
          isArrived = savedArrived;
        });
      }

      // Load pickup OTP sent status
      bool? savedOtpSent = await ApiService.getOtpSentStatus(orderId);
      if (savedOtpSent != null) {
        setState(() {
          isOtpSent = savedOtpSent;
        });
      }

      // Load pickup verification status
      bool? savedVerified = await ApiService.getVerificationStatus(orderId);
      if (savedVerified != null) {
        setState(() {
          isVerifying = savedVerified;
          isPickupVerified = savedVerified;
        });
      }

      // Load delivery arrival status
      bool? savedDeliveryArrived = await ApiService.getDeliveryArrivalStatus(
        orderId,
      );
      if (savedDeliveryArrived != null) {
        setState(() {
          isDeliveryArrived = savedDeliveryArrived;
        });
      }

      // Load delivery OTP sent status
      bool? savedDeliveryOtpSent = await ApiService.getDeliveryOtpSentStatus(
        orderId,
      );
      if (savedDeliveryOtpSent != null) {
        setState(() {
          isDeliveryOtpSent = savedDeliveryOtpSent;
        });
      }

      // Load delivery verification status
      bool? savedDeliveryVerified = await ApiService.getDeliveryVerifiedStatus(
        orderId,
      );
      if (savedDeliveryVerified != null) {
        setState(() {
          isDeliveryVerified = savedDeliveryVerified;
        });
      }
    }

    setState(() {
      _isLoadingState = false;
    });

    _initializeOrder();
    _startLiveLocation(); // This gets device location

    // Start location updates AFTER order is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });

    _debugOrderData();
    _debugPickupCarrierId();

    // Check if we need to show the bottom sheet after all initialization
    _checkAndShowBottomSheet();
    _checkAndShowDeliveryBottomSheet();
  }

  void _showDeliveryOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return PopScope(
                  canPop: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Handle bar
                              Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Close button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isDeliveryVerifying)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          isDeliveryOtpSent = false;
                                          _otpController.clear();
                                        });
                                      },
                                    ),
                                ],
                              ),

                              // Title
                              const Text(
                                "Verify Delivery",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Order #${order!.id}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Receiver info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order!
                                                    .receiverAddress
                                                    ?.receiverName ??
                                                "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            order!
                                                    .receiverAddress
                                                    ?.phoneNumber ??
                                                "",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Send OTP Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isDeliveryOtpSent
                                      ? null
                                      : () {
                                          setModalState(() {
                                            isDeliveryOtpSent = true;
                                          });
                                          _sendDeliveryOtp();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isDeliveryOtpSent
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "OTP Sent Successfully",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Send OTP to Receiver",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // OTP Input Field
                              if (isDeliveryOtpSent) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Enter 6-digit OTP",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: Pinput(
                                          controller: _otpController,
                                          length: 6,
                                          defaultPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          focusedPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          submittedPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onCompleted: (pin) {
                                            _verifyDeliveryOtp(pin);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Didn't receive OTP? ",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                isDeliveryOtpSent = true;
                                              });
                                              _resendDeliveryOtp();
                                            },
                                            child: const Text(
                                              "Resend",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isDeliveryVerifying
                                        ? null
                                        : () {
                                            if (_otpController.text.length ==
                                                6) {
                                              _verifyDeliveryOtp(
                                                _otpController.text,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Please enter 6-digit OTP",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: isDeliveryVerifying
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Verify & Complete Delivery",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],

                              // Helper text
                              if (!isDeliveryVerifying)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    "Complete verification to finish delivery",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          if (!isDeliveryVerifying) {
            isDeliveryOtpSent = false;
          }
          _otpController.clear();
        });
      }
    });
  }

  Future<void> _sendDeliveryOtp() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isSubmitting = false);
        return;
      }

      logger.i(
        "📱 Sending delivery OTP for pickup_carrier_id: $pickupCarrierId",
      );

      final response = await apiService.sendDeliveryOtp(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        setState(() {
          isDeliveryOtpSent = true;
        });

        if (order != null) {
          await ApiService.saveDeliveryOtpSentStatus(order!.id, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to receiver's phone"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String errorMsg = response?['error'] ?? "Failed to send OTP";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      logger.e("Error sending delivery OTP: $e");
      _showErrorSnackBar("Error sending OTP: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendDeliveryOtp() async {
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }

      final response = await apiService.sendDeliveryOtp(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String errorMsg = response?['error'] ?? "Failed to resend OTP";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      logger.e("Error resending delivery OTP: $e");
      _showErrorSnackBar("Error resending OTP: $e");
    }
  }

  void _checkAndShowDeliveryBottomSheet() {
    if (isDeliveryArrived && !isDeliveryVerified && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDeliveryOtpBottomSheet();
        }
      });
    }
  }

  @override
  Future<void> _initializeOrder() async {
    if (widget.order != null) {
      print("📦 Using provided order: ${widget.order!.id}");
      setState(() {
        order = widget.order;
        isLoading = false;
      });
    } else {
      print("🌐 No order provided, fetching from API: ${widget.orderId}");
      await _loadOrderDetails();
    }
  }

  Future<void> _loadOrderDetails() async {
    setState(() => isLoading = true);

    try {
      final fetchedOrder = await apiService.fetchOrderById(widget.orderId);

      if (mounted) {
        if (fetchedOrder != null) {
          setState(() {
            order = fetchedOrder;
            isLoading = false;
          });

          await ApiService.saveActiveOrder(widget.orderId);
        } else {
          setState(() {
            isLoading = false;
          });

          _showErrorSnackBar("Order not found. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        _showErrorSnackBar("Failed to load order details: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      carrierLocation = LatLng(position.latitude, position.longitude);
    });

    _locationStream?.cancel();
    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              carrierLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
  }

  void _openMapForDeliveryNavigation() {
    if (order?.receiverAddress == null) return;

    final receiverLat = order!.receiverAddress!.latitude;
    final receiverLng = order!.receiverAddress!.longitude;
    if (receiverLat == null || receiverLng == null) return;

    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${carrierLocation?.latitude},${carrierLocation?.longitude}&destination=$receiverLat,$receiverLng&travelmode=driving";
    _launchUrl(url);
  }

  void _openMapForNavigation() {
    if (order?.senderAddress == null) return;

    final senderLat = order!.senderAddress!.latitude;
    final senderLng = order!.senderAddress!.longitude;
    if (senderLat == null || senderLng == null) return;

    final url =
        "https://www.google.com/maps/dir/?api=1&origin=${carrierLocation?.latitude},${carrierLocation?.longitude}&destination=$senderLat,$senderLng&travelmode=driving";
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

  Future<void> _markArrived() async {
    setState(() => isSubmitting = true);

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        logger.e("❌ No pickup_carrier_id found in SharedPreferences!");
        _showErrorSnackBar(
          "No pickup carrier ID found. Please accept the order again.",
        );
        setState(() => isSubmitting = false);
        return;
      }

      logger.i(
        "✅ Using pickup_carrier_id from SharedPreferences: $pickupCarrierId",
      );
      logger.i("🚚 Attempting to mark arrived with ID: $pickupCarrierId");

      final response = await apiService.markArrivedSimple(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] != false) {
        setState(() {
          isArrived = true;
          isSubmitting = false;
        });

        if (order != null) {
          await ApiService.saveArrivalStatus(order!.id, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arrival confirmed successfully"),
            backgroundColor: Colors.green,
          ),
        );

        _showOtpBottomSheet();
      } else {
        setState(() => isSubmitting = false);
        String errorMsg = response?['error'] ?? "Failed to mark arrival";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      _showErrorSnackBar("Error: $e");
    }
  }

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return PopScope(
                  canPop: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isVerifying)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          isOtpSent = false;
                                          _otpController.clear();
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const Text(
                                "Verify Pickup",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Order #${order!.id}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person_outline,
                                        color: ColorConstants.red,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order!.senderAddress?.senderName ??
                                                "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            order!.senderAddress?.phoneNumber ??
                                                "",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isOtpSent
                                      ? null
                                      : () {
                                          setModalState(() {
                                            isOtpSent = true;
                                          });
                                          _sendOtp();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isOtpSent
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "OTP Sent Successfully",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Send OTP to Sender",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // OTP Input Field
                              if (isOtpSent) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Enter 6-digit OTP",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: Pinput(
                                          controller: _otpController,
                                          length: 6,
                                          defaultPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          focusedPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: ColorConstants.red,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: ColorConstants.red,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          submittedPinTheme: PinTheme(
                                            width: 50,
                                            height: 55,
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onCompleted: (pin) {
                                            _verifyOtp(pin);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Didn't receive OTP? ",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                isOtpSent = true;
                                              });
                                              _resendOtp();
                                            },
                                            child: const Text(
                                              "Resend",
                                              style: TextStyle(
                                                color: ColorConstants.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isVerifying
                                        ? null
                                        : () {
                                            if (_otpController.text.length ==
                                                6) {
                                              _verifyOtp(_otpController.text);
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Please enter 6-digit OTP",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: isVerifying
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Verify & Continue",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ],

                              // Helper text
                              if (!isVerifying)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    "Complete verification to proceed",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          if (!isVerifying) {
            isOtpSent = false;
          }
          _otpController.clear();
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isSubmitting = false);
        return;
      }

      logger.i("📱 Sending OTP for pickup_carrier_id: $pickupCarrierId");

      final response = await apiService.sendPickupOtp(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        setState(() {
          isOtpSent = true;
        });

        if (order != null) {
          await ApiService.saveOtpSentStatus(order!.id, true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to sender's phone"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String errorMsg = response?['error'] ?? "Failed to send OTP";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      logger.e("Error sending OTP: $e");
      _showErrorSnackBar("Error sending OTP: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }

      final response = await apiService.sendPickupOtp(
        pickupCarrierId: pickupCarrierId,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String errorMsg = response?['error'] ?? "Failed to resend OTP";
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      logger.e("Error resending OTP: $e");
      _showErrorSnackBar("Error resending OTP: $e");
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      isVerifying = true;
    });

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isVerifying = false);
        return;
      }

      final response = await apiService.verifyPickupOtp(
        pickupCarrierId: pickupCarrierId,
        otp: otp,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        if (order != null) {
          await ApiService.saveVerificationStatus(order!.id, true);
        }

        // Close bottom sheet
        Navigator.pop(context);

        // Switch to delivery mode
        setState(() {
          isPickupVerified = true;
          isVerifying = false;
          isOtpSent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pickup verified successfully! Proceed to delivery."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String errorMsg =
            response?['error'] ?? "Invalid OTP. Please try again.";
        _showErrorSnackBar(errorMsg);
        setState(() => isVerifying = false);
      }
    } catch (e) {
      logger.e("Error verifying OTP: $e");
      _showErrorSnackBar("Error verifying OTP: $e");
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot go back while an order is active"),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: _isLoadingState || isLoading
            ? const Center(child: CircularProgressIndicator())
            : order == null
            ? _buildErrorWidget()
            : _buildBody(),
        bottomSheet: _buildSliderButton(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            "Failed to load order details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Order ID: ${widget.orderId}",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "This order may no longer be active",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await ApiService.clearActiveOrder();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CarrierDashboard()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.dashboard),
            label: const Text("Go to Dashboard"),
          ),
        ],
      ),
    );
  }

  //   Future<void> _completeDelivery() async {
  //   if (order != null) {
  //     await ApiService.clearOrderStatus(order!.id);
  //     await ApiService.clearActiveOrder();
  //     await ApiService.clearPickupCarrierId();
  //     if (mounted) {
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (_) => const CarrierDashboard()),
  //         (route) => false,
  //       );
  //     }
  //   }
  // }

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 50),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Order Accepted Successfully",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.red,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Order #${order!.id}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            Lottie.asset(
              "assets/lottie_assets/delivery_boy.json",
              width: 180,
              height: 160,
              fit: BoxFit.fitWidth,
            ),
            Expanded(child: _buildPickupCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildPickupCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Icon(
                isPickupVerified ? Icons.location_on : Icons.location_on,
                color: isPickupVerified ? Colors.green : ColorConstants.red,
              ),
              const SizedBox(width: 8),
              Text(
                isPickupVerified ? "Delivery Location" : "Pickup Location",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPickupVerified ? Colors.green : ColorConstants.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isPickupVerified
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black12),
              ],
            ),
            child: Column(
              children: [
                // Person info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isPickupVerified
                          ? Colors.green.shade200
                          : const Color.fromARGB(255, 216, 215, 215),
                      child: Icon(
                        Icons.person,
                        color: isPickupVerified
                            ? Colors.green
                            : ColorConstants.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPickupVerified
                              ? (order!.receiverAddress?.receiverName ?? "")
                              : (order!.senderAddress?.senderName ?? ""),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          isPickupVerified
                              ? (order!.receiverAddress?.phoneNumber ?? "")
                              : (order!.senderAddress?.phoneNumber ?? ""),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Address details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPickupVerified
                                ? (order!.receiverAddress?.address ?? "")
                                : (order!.senderAddress?.address ?? ""),
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            isPickupVerified
                                ? "${order!.receiverAddress?.district ?? ""}, ${order!.receiverAddress?.state ?? ""}"
                                : "${order!.senderAddress?.district ?? ""}, ${order!.senderAddress?.state ?? ""}",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            isPickupVerified
                                ? (order!.receiverAddress?.country ?? "")
                                : (order!.senderAddress?.country ?? ""),
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            "ZIP: ${isPickupVerified ? (order!.receiverAddress?.zipCode ?? "") : (order!.senderAddress?.zipCode ?? "")}",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          if (isPickupVerified
                              ? order!.receiverAddress?.landmark != null
                              : order!.senderAddress?.landmark != null)
                            Text(
                              "Landmark: ${isPickupVerified ? order!.receiverAddress!.landmark : order!.senderAddress!.landmark}",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Navigate button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: isPickupVerified
                          ? _openMapForDeliveryNavigation
                          : _openMapForNavigation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPickupVerified
                              ? Colors.green
                              : ColorConstants.red,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isPickupVerified
                                          ? Colors.green
                                          : ColorConstants.red)
                                      .withOpacity(.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Navigate",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  "Tap to Navigate",
                  style: TextStyle(color: ColorConstants.grey, fontSize: 12),
                ),
                SizedBox(height: 5),

                // Distance
                if (carrierLocation != null)
                  Center(
                    child: isPickupVerified
                        ? (order!.receiverAddress?.latitude != null
                              ? _buildDeliveryDistance()
                              : const SizedBox())
                        : (order!.senderAddress?.latitude != null
                              ? _buildPickupDistance()
                              : const SizedBox()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDistance() {
    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.senderAddress!.latitude!,
      order!.senderAddress!.longitude!,
    );

    final km = (distance / 1000).toStringAsFixed(2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.route, color: ColorConstants.red),
        const SizedBox(width: 6),
        Text(
          "$km km away from pickup",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ColorConstants.red,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildDeliveryDistance() {
    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.receiverAddress!.latitude!,
      order!.receiverAddress!.longitude!,
    );

    final km = (distance / 1000).toStringAsFixed(2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.route, color: Colors.green),
        const SizedBox(width: 6),
        Text(
          "$km km away from delivery",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  void _checkAndShowBottomSheet() {
    if (isArrived && !isVerifying && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showOtpBottomSheet();
        }
      });
    }
  }

  Widget _buildSliderButton() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: isDeliveryVerified
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "✓ Delivery Completed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : (isPickupVerified
                  ? (isDeliveryArrived
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                "✓ Arrived at Delivery Location",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : SliderButton(
                            action: () async {
                              await _markDelivered();
                              return true;
                            },
                            buttonColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            highlightedColor: Colors.white,
                            baseColor: Colors.green,
                            label: const Text(
                              "Slide to confirm delivery arrival",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                            width: MediaQuery.of(context).size.width - 40,
                            height: 60,
                            radius: 30,
                            vibrationFlag: true,
                            shimmer: true,
                          ))
                  : (isArrived
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                "✓ Arrived at Pickup Location",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : SliderButton(
                            action: () async {
                              await _markArrived();
                              return true;
                            },
                            buttonColor: ColorConstants.red,
                            backgroundColor: Colors.grey.shade200,
                            highlightedColor: Colors.white,
                            baseColor: ColorConstants.red,
                            label: const Text(
                              "Slide to confirm pickup arrival",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            icon: const Icon(
                              Icons.double_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                            width: MediaQuery.of(context).size.width - 40,
                            height: 60,
                            radius: 30,
                            vibrationFlag: true,
                            shimmer: true,
                          ))),
      ),
    );
  }
  // Future<void> _markDelivered() async {
  //   setState(() => isSubmitting = true);

  //   try {
  //     // Add your delivery API call here
  //     // For example: await apiService.markDelivered(pickupCarrierId: pickupCarrierId);

  //     await Future.delayed(const Duration(seconds: 1)); // Simulate API call

  //     if (!mounted) return;

  //     // Clear all statuses and go to dashboard
  //     if (order != null) {
  //       await ApiService.clearOrderStatus(order!.id);
  //     }
  //     await ApiService.clearActiveOrder();
  //     await ApiService.clearPickupCarrierId();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Delivery completed successfully!"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );

  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const CarrierDashboard()),
  //       (route) => false,
  //     );
  //   } catch (e) {
  //     setState(() => isSubmitting = false);
  //     _showErrorSnackBar("Error: $e");
  //   }
  // }
}
