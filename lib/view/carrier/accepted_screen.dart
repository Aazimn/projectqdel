import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/model/order_model.dart';
import 'package:projectqdel/view/Carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/Carrier/delivery_finished_lottie.dart';
import 'package:projectqdel/view/Carrier/drop_location_screen.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:slider_button/slider_button.dart';
import 'package:pinput/pinput.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool isPickupVerified = false;

  bool isDeliveryArrived = false;
  bool isDeliveryOtpSent = false;
  bool isDeliveryVerifying = false;
  bool isDeliveryVerified = false;
  bool isCancelling = false;

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
    if (order == null) {
      logger.w(
        "Cannot start location updates: order is null, will retry in 1 second",
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startLocationUpdates();
      });
      return;
    }
    int? pickupCarrierId = await ApiService.getPickupCarrierId();

    if (pickupCarrierId == null) {
      logger.w("Cannot start location updates: missing pickup_carrier_id");
      return;
    }

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

    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted || !_isLocationUpdatesEnabled) {
        timer.cancel();
        return;
      }

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
    _startLiveLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });
  }

  @override
  void didUpdateWidget(covariant AcceptedOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.order != oldWidget.order) {
      _stopLocationUpdates();
      _startLocationUpdates();
    }
  }

  void _navigateToDropLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DropLocationScreen()),
    );
  }

  Future<void> _cancelOrder() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Cancel Order",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "No",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() {
      isCancelling = true;
    });

    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();

      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        setState(() => isCancelling = false);
        return;
      }

      final response = await apiService.cancelPickupOrder(pickupCarrierId);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        if (order != null) {
          await ApiService.clearOrderStatus(order!.id);
        }
        await ApiService.clearActiveOrder();
        await ApiService.clearPickupCarrierId();

        _stopLocationUpdates();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order cancelled successfully"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CarrierDashboard()),
          (route) => false,
        );
      } else {
        String errorMsg = response?['error'] ?? "Failed to cancel order";
        _showErrorSnackBar(errorMsg);
        setState(() => isCancelling = false);
      }
    } catch (e) {
      logger.e("Error cancelling order: $e");
      _showErrorSnackBar("Error cancelling order: $e");
      setState(() => isCancelling = false);
    }
  }

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
          MaterialPageRoute(builder: (_) => const DeliveryFinishedLottie()),
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
    if (widget.order != null) {
      int orderId = widget.order!.id;

      bool? savedArrived = await ApiService.getArrivalStatus(orderId);
      if (savedArrived != null) {
        setState(() {
          isArrived = savedArrived;
        });
      }

      bool? savedOtpSent = await ApiService.getOtpSentStatus(orderId);
      if (savedOtpSent != null) {
        setState(() {
          isOtpSent = savedOtpSent;
        });
      }

      bool? savedVerified = await ApiService.getVerificationStatus(orderId);
      if (savedVerified != null) {
        setState(() {
          isVerifying = savedVerified;
          isPickupVerified = savedVerified;
        });
      }

      bool? savedDeliveryArrived = await ApiService.getDeliveryArrivalStatus(
        orderId,
      );
      if (savedDeliveryArrived != null) {
        setState(() {
          isDeliveryArrived = savedDeliveryArrived;
        });
      }
      bool? savedDeliveryOtpSent = await ApiService.getDeliveryOtpSentStatus(
        orderId,
      );
      if (savedDeliveryOtpSent != null) {
        setState(() {
          isDeliveryOtpSent = savedDeliveryOtpSent;
        });
      }

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
    _startLiveLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationUpdates();
    });

    _debugOrderData();
    _debugPickupCarrierId();
    _checkAndShowBottomSheet();
    _checkAndShowDeliveryBottomSheet();
  }

  void _showOtpBottomSheet() {
    // Don't show if already verified
    if (isPickupVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pickup already verified!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Don't show if not arrived
    if (!isArrived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please arrive at pickup location first"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    OtpTimer.cancelTimer();
    bool isDismissible = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This is crucial - allows the sheet to resize
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      useSafeArea: true, // Add this to respect safe areas
      builder: (context) {
        return PopScope(
          canPop: isDismissible,
          onPopInvoked: (didPop) {
            if (!didPop && !isDismissible) {
              // Prevent closing
            } else if (didPop) {
              // Reset OTP sent flag when bottom sheet is dismissed
              if (mounted && !isVerifying) {
                setState(() {
                  isOtpSent = false;
                });
                _otpController.clear();
              }
            }
          },
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void startResendTimer() {
                OtpTimer.startTimer(() {
                  if (mounted) setModalState(() {});
                });
              }

              Future<void> handleResendOtp() async {
                if (OtpTimer.isTimerActive) return;
                setModalState(() {});
                await _resendOtp();
                if (mounted) setModalState(() => startResendTimer());
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Make content scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context)
                              .viewInsets
                              .bottom, // This is key - adds padding for keyboard
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_outlined,
                                      color: Colors.red.shade700,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Verify Pickup",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Order #${order!.id}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sender info card
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.red.shade700,
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
                                            ),
                                          ),
                                          Text(
                                            order!.senderAddress?.phoneNumber ??
                                                "",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Send OTP button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ElevatedButton(
                                onPressed: isOtpSent
                                    ? null
                                    : () async {
                                        setModalState(() => isOtpSent = true);
                                        await _sendOtp();
                                        if (mounted)
                                          setModalState(
                                            () => startResendTimer(),
                                          );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
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
                                            style: TextStyle(fontSize: 16),
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

                            const SizedBox(height: 12),

                            // Cancel button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: OutlinedButton(
                                onPressed: isCancelling ? null : _cancelOrder,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isCancelling
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Cancel Order",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OTP Input Section
                            if (isOtpSent) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Enter 6-digit OTP",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        focusedPinTheme: PinTheme(
                                          width: 50,
                                          height: 55,
                                          textStyle: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.red.shade700,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onCompleted: (pin) => _verifyOtp(pin),
                                        autofocus:
                                            true, // Auto-focus when OTP is sent
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
                                          onTap: OtpTimer.isTimerActive
                                              ? null
                                              : handleResendOtp,
                                          child: Text(
                                            OtpTimer.timerText,
                                            style: TextStyle(
                                              color: OtpTimer.isTimerActive
                                                  ? Colors.grey
                                                  : Colors.red.shade700,
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: SizedBox(
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
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade700,
                                      minimumSize: const Size(
                                        double.infinity,
                                        54,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
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
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else
                              const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      OtpTimer.cancelTimer();
      if (mounted && !isVerifying) {
        setState(() {
          isOtpSent = false;
        });
        _otpController.clear();
      }
    });
  }

  void _showDeliveryOtpBottomSheet() {
    // Don't show if already verified
    if (isDeliveryVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery already verified!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Don't show if not arrived
    if (!isDeliveryArrived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please arrive at delivery location first"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    OtpTimer.cancelTimer();
    bool isDismissible = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This is crucial - allows the sheet to resize
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      useSafeArea: true, // Add this to respect safe areas
      builder: (context) {
        return PopScope(
          canPop: isDismissible,
          onPopInvoked: (didPop) {
            if (!didPop && !isDismissible) {
            } else if (didPop) {
              // Reset OTP sent flag when bottom sheet is dismissed
              if (mounted && !isDeliveryVerifying) {
                setState(() {
                  isDeliveryOtpSent = false;
                });
                _otpController.clear();
              }
            }
          },
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void startResendTimer() {
                OtpTimer.startTimer(() {
                  if (mounted) setModalState(() {});
                });
              }

              Future<void> handleResendOtp() async {
                if (OtpTimer.isTimerActive) return;
                setModalState(() {});
                await _resendDeliveryOtp();
                if (mounted) setModalState(() => startResendTimer());
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Make content scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context)
                              .viewInsets
                              .bottom, // This is key - adds padding for keyboard
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_outlined,
                                      color: Colors.green,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Verify Delivery",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Order #${order!.id}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Receiver info card
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.person,
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
                                            ),
                                          ),
                                          Text(
                                            order!
                                                    .receiverAddress
                                                    ?.phoneNumber ??
                                                "",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Send OTP button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ElevatedButton(
                                onPressed: isDeliveryOtpSent
                                    ? null
                                    : () async {
                                        setModalState(
                                          () => isDeliveryOtpSent = true,
                                        );
                                        await _sendDeliveryOtp();
                                        if (mounted)
                                          setModalState(
                                            () => startResendTimer(),
                                          );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
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
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        "Send OTP to Receiver",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Drop Order button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: OutlinedButton(
                                onPressed: isCancelling ? null : _cancelOrder,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isCancelling
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Drop Order",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OTP Input Section
                            if (isDeliveryOtpSent) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Enter 6-digit OTP",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onCompleted: (pin) =>
                                            _verifyDeliveryOtp(pin),
                                        autofocus:
                                            true, // Auto-focus when OTP is sent
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
                                          onTap: OtpTimer.isTimerActive
                                              ? null
                                              : handleResendOtp,
                                          child: Text(
                                            OtpTimer.timerText,
                                            style: TextStyle(
                                              color: OtpTimer.isTimerActive
                                                  ? Colors.grey
                                                  : Colors.green,
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: SizedBox(
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
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize: const Size(
                                        double.infinity,
                                        54,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
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
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else
                              const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      OtpTimer.cancelTimer();
      if (mounted && !isDeliveryVerifying) {
        setState(() {
          isDeliveryOtpSent = false;
        });
        _otpController.clear();
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
        Navigator.pop(context);

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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            "Failed to load order details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Order ID: ${widget.orderId}",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropLocationConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.store, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Drop Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proceed to drop location?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can select nearby drop locations for delivery',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToDropLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
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

  Widget _buildModernLocationCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPickupVerified
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isPickupVerified ? Icons.location_on : Icons.location_pin,
                  color: isPickupVerified ? Colors.green : Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPickupVerified
                          ? "Delivery Location"
                          : "Pickup Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPickupVerified
                            ? Colors.green
                            : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      isPickupVerified
                          ? "Final destination"
                          : "Collect parcel from here",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              Container(
                decoration: BoxDecoration(
                  color: isPickupVerified ? Colors.green : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: InkWell(
                  onTap: () {
                    if (!isCancelling) {
                      if (isPickupVerified) {
                        _showDropLocationConfirmation();
                      } else {
                        _cancelOrder();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: isCancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon(
                              //   isPickupVerified ? Icons.store : Icons.cancel,
                              //   color: Colors.white,
                              //   size: 18,
                              // ),
                              // const SizedBox(width: 6),
                              Text(
                                isPickupVerified ? "Drop Order" : "Cancel",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPickupVerified
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: isPickupVerified
                        ? Colors.green
                        : Colors.red.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPickupVerified
                            ? (order!.receiverAddress?.receiverName ?? "")
                            : (order!.senderAddress?.senderName ?? ""),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPickupVerified
                            ? (order!.receiverAddress?.phoneNumber ?? "")
                            : (order!.senderAddress?.phoneNumber ?? ""),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Call button
                GestureDetector(
                  onTap: () {
                    final phoneNumber = isPickupVerified
                        ? order!.receiverAddress?.phoneNumber
                        : order!.senderAddress?.phoneNumber;

                    if (phoneNumber != null && phoneNumber.isNotEmpty) {
                      _makePhoneCall(phoneNumber);
                    } else {
                      _showErrorSnackBar("Phone number not available");
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.call,
                      color: isPickupVerified
                          ? Colors.green
                          : Colors.red.shade700,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Address section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Address Details",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPickupVerified
                      ? (order!.receiverAddress?.address ?? "")
                      : (order!.senderAddress?.address ?? ""),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isPickupVerified
                      ? "${order!.receiverAddress?.district ?? ""}, ${order!.receiverAddress?.state ?? ""}"
                      : "${order!.senderAddress?.district ?? ""}, ${order!.senderAddress?.state ?? ""}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (isPickupVerified
                    ? order!.receiverAddress?.landmark != null
                    : order!.senderAddress?.landmark != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Landmark: ${isPickupVerified ? order!.receiverAddress!.landmark : order!.senderAddress!.landmark}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                Text(
                  "ZIP: ${isPickupVerified ? (order!.receiverAddress?.zipCode ?? "") : (order!.senderAddress?.zipCode ?? "")}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Distance and navigate button
          if (carrierLocation != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isPickupVerified ? Colors.green : Colors.red)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: isPickupVerified
                            ? Colors.green
                            : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPickupVerified
                                ? "Distance to delivery"
                                : "Distance to pickup",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            isPickupVerified
                                ? _getDeliveryDistance()
                                : _getPickupDistance(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPickupVerified
                                  ? Colors.green
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: isPickupVerified
                        ? _openMapForDeliveryNavigation
                        : _openMapForNavigation,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text("Navigate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPickupVerified
                          ? Colors.green
                          : Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar("Phone number is empty");
      return;
    }

    String formattedNumber = phoneNumber.trim();

    if (RegExp(r'^\d{10}$').hasMatch(formattedNumber)) {
      formattedNumber = '+91$formattedNumber';
    }

    final String telUrl = 'tel:$formattedNumber';

    try {
      await launchUrl(Uri.parse(telUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showCallFailedDialog(phoneNumber);
    }
  }

  void _showCallFailedDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cannot Make Call"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Unable to open dialer automatically."),
            const SizedBox(height: 12),
            Text("Please call manually: $phoneNumber"),
            const SizedBox(height: 8),
            const Text(
              "Note: Make sure you're using a real device or an emulator with telephony support.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: phoneNumber));
              _showErrorSnackBar("Number copied to clipboard");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text("Copy Number"),
          ),
        ],
      ),
    );
  }

  String _getPickupDistance() {
    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.senderAddress!.latitude!,
      order!.senderAddress!.longitude!,
    );
    final km = (distance / 1000).toStringAsFixed(2);
    return "$km km";
  }

  String _getDeliveryDistance() {
    final distance = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.receiverAddress!.latitude!,
      order!.receiverAddress!.longitude!,
    );
    final km = (distance / 1000).toStringAsFixed(2);
    return "$km km";
  }

  void _reopenPickupOtpSheet() {
    if (isArrived && !isVerifying && !isPickupVerified) {
      _showOtpBottomSheet();
    }
  }

  void _reopenDeliveryOtpSheet() {
    if (isDeliveryArrived && !isDeliveryVerifying && !isDeliveryVerified) {
      _showDeliveryOtpBottomSheet();
    }
  }

  Widget _buildModernSliderButton() {
    if (isDeliveryVerified) {
      return _buildCompletionCard("Delivery Completed ✓", Colors.green);
    }

    if (isPickupVerified) {
      if (isDeliveryArrived) {
        return _buildCompletionCard(
          "Arrived at Delivery Location",
          Colors.green,
          onTap: _reopenDeliveryOtpSheet,
        );
      }
      return _buildDeliverySlider();
    }

    if (isArrived) {
      return _buildCompletionCard(
        "Arrived at Pickup Location",
        Colors.green,
        onTap: _reopenPickupOtpSheet,
      );
    }

    return _buildPickupSlider();
  }

  Widget _buildCompletionCard(String text, Color color, {VoidCallback? onTap}) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupSlider() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SliderButton(
          action: () async {
            await _markArrived();
            return true;
          },
          buttonColor: Colors.red.shade700,
          backgroundColor: Colors.grey.shade100,
          highlightedColor: Colors.white,
          baseColor: Colors.red.shade700,
          label: const Text(
            "Slide to confirm pickup arrival",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          icon: Center(
            child: Icon(Icons.arrow_forward, color: Colors.white, size: 24),
          ),
          width: MediaQuery.of(context).size.width - 40,
          height: 60,
          radius: 30,
          vibrationFlag: true,
          shimmer: true,
        ),
      ),
    );
  }

  Widget _buildDeliverySlider() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SliderButton(
          action: () async {
            await _markDelivered();
            return true;
          },
          buttonColor: Colors.green,
          backgroundColor: Colors.grey.shade100,
          highlightedColor: Colors.white,
          baseColor: Colors.green,
          label: const Text(
            "Slide to confirm delivery arrival",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          icon: Center(child: Icon(Icons.check, color: Colors.white, size: 24)),
          width: MediaQuery.of(context).size.width - 40,
          height: 60,
          radius: 30,
          vibrationFlag: true,
          shimmer: true,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Active Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'You have an active order. Going back will cancel the delivery process.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.clearActiveOrder();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CarrierDashboard()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exit Anyway'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade700, Colors.red.shade400],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Order Accepted Successfully",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

        Expanded(child: _buildModernLocationCard()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoadingState || isLoading
            ? const Center(child: CircularProgressIndicator())
            : order == null
            ? _buildErrorWidget()
            : _buildBody(),
        bottomSheet: _buildModernSliderButton(),
      ),
    );
  }
}

class OtpTimer {
  static const int resendSeconds = 60;

  static Timer? _timer;
  static int _remainingSeconds = 0;
  static VoidCallback? _onTick;

  static void startTimer(VoidCallback onTick) {
    _onTick = onTick;
    _remainingSeconds = resendSeconds;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _onTick?.call();
      } else {
        timer.cancel();
        _onTick?.call();
      }
    });
  }

  static bool get isTimerActive => _remainingSeconds > 0;

  static String get timerText {
    if (_remainingSeconds == 0) return "Resend";
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "Resend in $minutes:$seconds";
  }

  static void cancelTimer() {
    _timer?.cancel();
    _remainingSeconds = 0;
  }

  static void resetTimer() {
    _remainingSeconds = resendSeconds;
  }
}
