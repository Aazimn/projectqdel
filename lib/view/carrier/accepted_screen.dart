import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:url_launcher/url_launcher.dart';

class PickupStatusHelper {
  static const String pending = 'pending';
  static const String arrived = 'arrived';
  static const String pickedUp = 'picked_up';
  static const String dropStarted = 'drop_started';
  static const String arrivedAtDrop = 'arrived_at_drop';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  static const String dropAssigned = 'drop_assigned';
  static const String arrivedAtShop = 'arrived_at_shop';
  static const String droppedAtShop = 'dropped_at_shop';
  static const String dispatchedFromShop = 'dispatched_from_shop';

  static String getCurrentPickupCarrierStatus(List<dynamic> timeline) {
    for (var event in timeline.reversed) {
      if (event['actor'] == 'shop' && event['status'] == droppedAtShop) {
        break;
      }

      if (event['actor'] == 'carrier' &&
          [
            pending,
            arrived,
            pickedUp,
            dropStarted,
            arrivedAtDrop,
            delivered,
          ].contains(event['status'])) {
        return event['status'];
      }
    }
    return pending;
  }

  static String getCurrentShopDropStatus(List<dynamic> timeline) {
    for (var event in timeline.reversed) {
      if (event['actor'] == 'shop' &&
          [
            dropAssigned,
            arrivedAtShop,
            droppedAtShop,
            dispatchedFromShop,
          ].contains(event['status'])) {
        return event['status'];
      }
    }
    return dropAssigned;
  }

  static Map<String, dynamic>? getShopDropDetails(List<dynamic> timeline) {
    for (var event in timeline.reversed) {
      if (event['actor'] == 'shop' && event['details'] != null) {
        return event['details'];
      }
    }
    return null;
  }

  static bool isPickupArrived(String status) => status == arrived;
  static bool isPickupVerified(String status) =>
      status == pickedUp ||
      status == dropStarted ||
      status == arrivedAtDrop ||
      status == delivered;

  static bool isShopDropArrived(String status) => status == arrivedAtShop;

  static bool isShopDropCompleted(String status) =>
      status == droppedAtShop || status == dispatchedFromShop;

  static bool isDeliveryArrived(String status) => status == arrivedAtDrop;

  static bool isDeliveryVerified(String status) => status == delivered;
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
}

class AcceptedOrderScreen extends StatefulWidget {
  final int orderId;
  final OrderModel? order;
  final int? selectedShopDropId;

  const AcceptedOrderScreen({
    super.key,
    required this.orderId,
    this.order,
    this.selectedShopDropId,
  });

  @override
  State<AcceptedOrderScreen> createState() => _AcceptedOrderScreenState();
}

class _AcceptedOrderScreenState extends State<AcceptedOrderScreen> {
  final ApiService apiService = ApiService();
  OrderModel? order;
  bool isLoading = true;
  bool isSubmitting = false;
  bool isCancelling = false;

  String _pickupCarrierStatus = 'pending';
  String _shopDropStatus = 'drop_assigned';
  Map<String, dynamic>? _shopDropDetails;

  bool get isPickupArrived =>
      PickupStatusHelper.isPickupArrived(_pickupCarrierStatus) ||
      (!isPickupVerified &&
          _shopDropStatus == PickupStatusHelper.arrivedAtShop);
  bool get isPickupVerified =>
      PickupStatusHelper.isPickupVerified(_pickupCarrierStatus) ||
      _shopDropStatus == PickupStatusHelper.dispatchedFromShop;
  bool get isDeliveryArrived =>
      PickupStatusHelper.isDeliveryArrived(_pickupCarrierStatus);
  bool get isDeliveryCompleted =>
      PickupStatusHelper.isDeliveryVerified(_pickupCarrierStatus);

  bool get hasShopDrop =>
      widget.selectedShopDropId != null || _shopDropDetails != null;
  bool get isShopDropCompleted =>
      PickupStatusHelper.isShopDropCompleted(_shopDropStatus);
  bool get isShopDropArrived =>
      PickupStatusHelper.isShopDropArrived(_shopDropStatus);

  bool get isPickupStage => !isPickupVerified;
  bool get needsToDropAtShop =>
      widget.selectedShopDropId != null && !isShopDropCompleted;
  bool get isShopDropStage => isPickupVerified && needsToDropAtShop;
  bool get isDeliveryStage => isPickupVerified && !isShopDropStage;
  bool get pickingUpFromShop =>
      isPickupStage && hasShopDrop && isShopDropCompleted;

  bool isOtpSent = false;
  bool isVerifying = false;
  bool isDeliveryOtpSent = false;
  bool isDeliveryVerifying = false;
  bool isShopDropOtpSent = false;
  bool isShopDropVerifying = false;
  bool isUploadingImage = false;
  bool isConfirmingShopArrival = false;

  bool _isPickupOtpSheetOpen = false;
  bool _isDeliveryOtpSheetOpen = false;
  bool _isShopDropOtpSheetOpen = false;
  bool _isImageSheetOpen = false;
  String? _manualShopDropStatus;

  final TextEditingController _otpController = TextEditingController();
  LatLng? carrierLocation;
  StreamSubscription<Position>? _locationStream;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.order != null) {
      setState(() => order = widget.order);
    } else {
      await _loadOrderDetails();
    }

    await _fetchStatusFromBackend();

    await _startLiveLocation();
    _startLocationUpdates();

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchStatusFromBackend() async {
    try {
      final response = await apiService.getShipmentStatus(widget.orderId);

      if (response != null && response['status'] == 'success') {
        final timeline = response['data']['tracking']['timeline'] as List;
        debugPrint("📜 FULL TIMELINE: $timeline");

        _pickupCarrierStatus = PickupStatusHelper.getCurrentPickupCarrierStatus(
          timeline,
        );
        _shopDropStatus =
            _manualShopDropStatus ??
            PickupStatusHelper.getCurrentShopDropStatus(timeline);
        _shopDropDetails = PickupStatusHelper.getShopDropDetails(timeline);

        debugPrint("📊 STATUS UPDATE:");
        debugPrint("   - Carrier Status: $_pickupCarrierStatus");
        debugPrint("   - Shop Status: $_shopDropStatus");
        debugPrint("   - isPickupVerified: $isPickupVerified");
        debugPrint("   - hasShopDrop: $hasShopDrop");
        debugPrint("   - isShopDropCompleted: $isShopDropCompleted");

        _showUIForCurrentStatus();
      }
    } catch (e) {
      print("Error fetching status: $e");
    }
  }

  void _showUIForCurrentStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isPickupArrived &&
          !isPickupVerified &&
          !isVerifying &&
          !_isPickupOtpSheetOpen) {
        _showPickupOtpSheet();
      } else if (isDeliveryArrived &&
          !isDeliveryCompleted &&
          !isDeliveryVerifying &&
          !_isDeliveryOtpSheetOpen) {
        _showDeliveryOtpSheet();
      } else if (isShopDropStage && isShopDropArrived) {
        final bool hasImage = _shopDropDetails?['image'] != null;
        if (hasImage) {
          if (!_isShopDropOtpSheetOpen && !_isImageSheetOpen) {
            _showShopDropOtpSheet();
          }
        } else {
          if (!_isImageSheetOpen && !_isShopDropOtpSheetOpen) {
            _showImageUploadSheet();
          }
        }
      }
    });
  }

  Future<void> _refreshStatus() async {
    await _fetchStatusFromBackend();
    if (mounted) setState(() {});
  }

  Future<void> _markPickupArrived() async {
    if (isPickupArrived) return;
    setState(() => isSubmitting = true);
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }
      final response = await apiService.markArrivedSimple(
        pickupCarrierId: pickupCarrierId,
      );
      if (!mounted) return;
      if (response != null && response['success'] != false) {
        await _refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arrival confirmed successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Failed to mark arrival");
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _sendPickupOtp() async {
    setState(() => isSubmitting = true);
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
        setState(() => isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to sender's phone"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showErrorSnackBar("Error sending OTP: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _resendPickupOtp() async => _sendPickupOtp();

  Future<void> _verifyPickupOtp(String otp) async {
    setState(() => isVerifying = true);
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }
      final response = await apiService.verifyPickupOtp(
        pickupCarrierId: pickupCarrierId,
        otp: otp,
      );
      if (!mounted) return;
      if (response != null && response['success'] == true) {
        Navigator.pop(context);
        _isPickupOtpSheetOpen = false;
        await _refreshStatus();
        _otpController.clear();
        setState(() => isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pickup verified successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Invalid OTP");
        setState(() => isVerifying = false);
      }
    } catch (e) {
      _showErrorSnackBar("Error verifying OTP: $e");
      setState(() => isVerifying = false);
    }
  }

  void _showPickupOtpSheet() {
    if (_isPickupOtpSheetOpen || isPickupVerified) return;
    _isPickupOtpSheetOpen = true;
    OtpTimer.cancelTimer();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop && mounted && !isVerifying) {
            setState(() => isOtpSent = false);
            _otpController.clear();
          }
        },
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void startTimer() => OtpTimer.startTimer(() {
              if (mounted) setModalState(() {});
            });
            Future<void> handleResend() async {
              if (OtpTimer.isTimerActive) return;
              await _resendPickupOtp();
              if (mounted) setModalState(startTimer);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _sheetIcon(
                              Icons.verified_outlined,
                              Colors.red.shade50,
                              Colors.red.shade700,
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
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            _contactCard(
                              Colors.red.shade50,
                              Icons.person,
                              Colors.red.shade700,
                              order!.senderAddress?.senderName ?? "",
                              order!.senderAddress?.phoneNumber ?? "",
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isOtpSent
                                  ? null
                                  : () async {
                                      setModalState(() => isOtpSent = true);
                                      await _sendPickupOtp();
                                      if (mounted) setModalState(startTimer);
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
                                  ? _sentRow()
                                  : const Text(
                                      "Send OTP to Sender",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
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
                            const SizedBox(height: 20),
                            if (isOtpSent) ...[
                              _otpEntryCard(
                                controller: _otpController,
                                focusColor: Colors.red.shade700,
                                timerText: OtpTimer.timerText,
                                timerActive: OtpTimer.isTimerActive,
                                onResend: handleResend,
                                onCompleted: (pin) => _verifyPickupOtp(pin),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isVerifying
                                    ? null
                                    : () {
                                        _otpController.text.length == 6
                                            ? _verifyPickupOtp(
                                                _otpController.text,
                                              )
                                            : ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Please enter 6-digit OTP",
                                                  ),
                                                ),
                                              );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isVerifying
                                    ? _loadingIndicator()
                                    : const Text(
                                        "Verify & Continue",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      _isPickupOtpSheetOpen = false;
      OtpTimer.cancelTimer();
      if (mounted && !isVerifying) {
        setState(() => isOtpSent = false);
        _otpController.clear();
      }
    });
  }

  Future<void> _confirmShopDropArrival() async {
    if (widget.selectedShopDropId == null) {
      _showErrorSnackBar("No drop location selected");
      return;
    }
    setState(() => isConfirmingShopArrival = true);
    try {
      final response = await apiService.confirmShopDropArrival(
        widget.selectedShopDropId!,
      );
      if (!mounted) return;

      if (response != null && response['success'] == true) {
        if (response['data'] != null && response['data']['status'] != null) {
          _manualShopDropStatus = response['data']['status'];
        }
        await _refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arrived at drop location successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _showImageUploadSheet();
      } else {
        final errorDetail = response?['error'] ?? response?['detail'] ?? '';
        final bool alreadyArrived =
            errorDetail.toString().toLowerCase().contains('arrived_at_shop') ||
            errorDetail.toString().toLowerCase().contains(
              'cannot mark arrived',
            );

        if (alreadyArrived) {
          _manualShopDropStatus = PickupStatusHelper.arrivedAtShop;
          await _refreshStatus();
          final bool hasImage = _shopDropDetails?['image'] != null;
          if (hasImage) {
            _showShopDropOtpSheet();
          } else {
            _showImageUploadSheet();
          }
        } else {
          _showErrorSnackBar(
            errorDetail.isNotEmpty ? errorDetail : "Failed to confirm arrival",
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isConfirmingShopArrival = false);
    }
  }

  void _showImageUploadSheet() {
    if (_isImageSheetOpen) return;
    _isImageSheetOpen = true;
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt, size: 60, color: Colors.orange),
                      SizedBox(height: 16),
                      Text(
                        "Upload Product Photo",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Please take a photo of the product at drop location",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null)
                        setModalState(() => selectedImage = File(image.path));
                    },
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap to take photo",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUploadingImage || selectedImage == null
                          ? null
                          : () async {
                              setModalState(() => isUploadingImage = true);
                              final response = await apiService
                                  .uploadShopDropImage(
                                    shopDropId: widget.selectedShopDropId!,
                                    image: selectedImage!,
                                  );
                              setModalState(() => isUploadingImage = false);
                              if (response != null &&
                                  response['success'] == true) {
                                Navigator.pop(context);
                                _isImageSheetOpen = false;
                                await _refreshStatus();
                                _showShopDropOtpSheet();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Failed to upload image. Please try again.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isUploadingImage
                          ? _loadingIndicator()
                          : const Text(
                              "Upload & Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isImageSheetOpen = false);
    });
  }

  Future<void> _sendShopDropOtp() async {
    setState(() => isSubmitting = true);
    try {
      final response = await apiService.sendShopDropOtp(
        shopDropId: widget.selectedShopDropId!,
      );
      if (!mounted) return;
      if (response != null && response['success'] == true) {
        setState(() => isShopDropOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to shop"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showErrorSnackBar("Error sending OTP: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _resendShopDropOtp() async => _sendShopDropOtp();

  Future<void> _verifyShopDropOtp(String otp) async {
    if (widget.selectedShopDropId == null) return;
    setState(() => isShopDropVerifying = true);
    try {
      final response = await apiService.verifyShopDropOtp(
        shopDropId: widget.selectedShopDropId!,
        otp: otp,
      );
      if (!mounted) return;
      if (response != null && response['success'] == true) {
        await ApiService.clearActiveDropId();
        await ApiService.clearActiveOrder();
        await ApiService.clearPickupCarrierId();
        await ApiService.clearActiveOrderDetails();
        _stopLocationUpdates();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Drop completed successfully! Thank you."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryFinishedLottie()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Invalid OTP");
        setState(() => isShopDropVerifying = false);
      }
    } catch (e) {
      _showErrorSnackBar("Error verifying OTP: $e");
      setState(() => isShopDropVerifying = false);
    }
  }

  void _showShopDropOtpSheet() {
    if (_isShopDropOtpSheetOpen) return;
    _isShopDropOtpSheetOpen = true;
    OtpTimer.cancelTimer();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop && mounted && !isShopDropVerifying) {
            setState(() => isShopDropOtpSent = false);
            _otpController.clear();
          }
        },
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void startTimer() => OtpTimer.startTimer(() {
              if (mounted) setModalState(() {});
            });
            Future<void> handleResend() async {
              if (OtpTimer.isTimerActive) return;
              await _resendShopDropOtp();
              if (mounted) setModalState(startTimer);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _sheetIcon(
                              Icons.verified_outlined,
                              Colors.orange.shade50,
                              Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Verify Drop",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Order #${order!.id}",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            _contactCard(
                              Colors.orange.shade50,
                              Icons.store,
                              Colors.orange,
                              _shopDropDetails?['shop_name'] ??
                                  _shopDropDetails?['owner_name'] ??
                                  "Shop",
                              _shopDropDetails?['phone'] ?? "",
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isShopDropOtpSent
                                  ? null
                                  : () async {
                                      setModalState(
                                        () => isShopDropOtpSent = true,
                                      );
                                      await _sendShopDropOtp();
                                      if (mounted) setModalState(startTimer);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isShopDropOtpSent
                                  ? _sentRow()
                                  : const Text(
                                      "Send OTP to Shop",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            if (isShopDropOtpSent) ...[
                              _otpEntryCard(
                                controller: _otpController,
                                focusColor: Colors.orange,
                                timerText: OtpTimer.timerText,
                                timerActive: OtpTimer.isTimerActive,
                                onResend: handleResend,
                                onCompleted: (pin) => _verifyShopDropOtp(pin),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isShopDropVerifying
                                    ? null
                                    : () {
                                        _otpController.text.length == 6
                                            ? _verifyShopDropOtp(
                                                _otpController.text,
                                              )
                                            : ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Please enter 6-digit OTP",
                                                  ),
                                                ),
                                              );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isShopDropVerifying
                                    ? _loadingIndicator()
                                    : const Text(
                                        "Verify & Complete Drop",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isShopDropOtpSheetOpen = false;
          if (!isShopDropVerifying) {
            isShopDropOtpSent = false;
            _otpController.clear();
          }
        });
      }
    });
  }

  Future<void> _markDeliveryArrived() async {
    if (isDeliveryArrived) return;
    setState(() => isSubmitting = true);
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }
      final response = await apiService.markDelivered(
        pickupCarrierId: pickupCarrierId,
      );
      if (!mounted) return;
      if (response != null && response['success'] != false) {
        await _refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arrived at delivery location"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(
          response?['error'] ?? "Failed to mark delivery arrival",
        );
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _sendDeliveryOtp() async {
    setState(() => isSubmitting = true);
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
        setState(() => isDeliveryOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to receiver's phone"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showErrorSnackBar("Error sending OTP: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _resendDeliveryOtp() async => _sendDeliveryOtp();

  Future<void> _verifyDeliveryOtp(String otp) async {
    setState(() => isDeliveryVerifying = true);
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) {
        _showErrorSnackBar("No pickup carrier ID found");
        return;
      }
      final response = await apiService.verifyDeliveryOtp(
        pickupCarrierId: pickupCarrierId,
        otp: otp,
      );
      if (!mounted) return;
      if (response != null && response['success'] == true) {
        await ApiService.clearActiveDropId();
        await ApiService.clearActiveOrder();
        await ApiService.clearPickupCarrierId();
        await ApiService.clearActiveOrderDetails();
        _stopLocationUpdates();
        Navigator.pop(context);
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
        _showErrorSnackBar(response?['error'] ?? "Invalid OTP");
        setState(() => isDeliveryVerifying = false);
      }
    } catch (e) {
      _showErrorSnackBar("Error verifying OTP: $e");
      setState(() => isDeliveryVerifying = false);
    }
  }

  void _showDeliveryOtpSheet() {
    if (_isDeliveryOtpSheetOpen || isDeliveryCompleted) return;
    _isDeliveryOtpSheetOpen = true;
    OtpTimer.cancelTimer();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop && mounted && !isDeliveryVerifying) {
            setState(() => isDeliveryOtpSent = false);
            _otpController.clear();
          }
        },
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void startTimer() => OtpTimer.startTimer(() {
              if (mounted) setModalState(() {});
            });
            Future<void> handleResend() async {
              if (OtpTimer.isTimerActive) return;
              await _resendDeliveryOtp();
              if (mounted) setModalState(startTimer);
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _sheetIcon(
                              Icons.verified_outlined,
                              Colors.green.shade50,
                              Colors.green,
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
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            _contactCard(
                              Colors.green.shade50,
                              Icons.person,
                              Colors.green,
                              order!.receiverAddress?.receiverName ?? "",
                              order!.receiverAddress?.phoneNumber ?? "",
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isDeliveryOtpSent
                                  ? null
                                  : () async {
                                      setModalState(
                                        () => isDeliveryOtpSent = true,
                                      );
                                      await _sendDeliveryOtp();
                                      if (mounted) setModalState(startTimer);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isDeliveryOtpSent
                                  ? _sentRow()
                                  : const Text(
                                      "Send OTP to Receiver",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            if (isDeliveryOtpSent) ...[
                              _otpEntryCard(
                                controller: _otpController,
                                focusColor: Colors.green,
                                timerText: OtpTimer.timerText,
                                timerActive: OtpTimer.isTimerActive,
                                onResend: handleResend,
                                onCompleted: (pin) => _verifyDeliveryOtp(pin),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isDeliveryVerifying
                                    ? null
                                    : () {
                                        _otpController.text.length == 6
                                            ? _verifyDeliveryOtp(
                                                _otpController.text,
                                              )
                                            : ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Please enter 6-digit OTP",
                                                  ),
                                                ),
                                              );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isDeliveryVerifying
                                    ? _loadingIndicator()
                                    : const Text(
                                        "Verify & Complete Delivery",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      _isDeliveryOtpSheetOpen = false;
      OtpTimer.cancelTimer();
      if (mounted && !isDeliveryVerifying) {
        setState(() => isDeliveryOtpSent = false);
        _otpController.clear();
      }
    });
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
    setState(() => isCancelling = true);
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
        await ApiService.clearActiveDropId();
        await ApiService.clearActiveOrder();
        await ApiService.clearPickupCarrierId();
        _stopLocationUpdates();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order cancelled successfully"),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CarrierDashboard()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar(response?['error'] ?? "Failed to cancel order");
        setState(() => isCancelling = false);
      }
    } catch (e) {
      _showErrorSnackBar("Error cancelling order: $e");
      setState(() => isCancelling = false);
    }
  }

  void _navigateToDropLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DropLocationScreen(orderId: widget.orderId, order: order),
      ),
    ).then((result) async {
      if (result != null && result is int) {
        await ApiService.saveActiveDropId(result);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AcceptedOrderScreen(
              orderId: widget.orderId,
              order: order,
              selectedShopDropId: result,
            ),
          ),
        );
      }
    });
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
            child: const Text('Proceed', style: TextStyle(color: Colors.white)),
          ),
        ],
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
    if (mounted)
      setState(
        () => carrierLocation = LatLng(position.latitude, position.longitude),
      );
    _locationStream?.cancel();
    _locationStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (mounted)
            setState(
              () => carrierLocation = LatLng(pos.latitude, pos.longitude),
            );
        });
  }

  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted || isDeliveryCompleted) {
        timer.cancel();
        return;
      }
      await _sendCurrentLocation();
    });
  }

  Future<void> _sendCurrentLocation() async {
    if (carrierLocation == null) return;
    try {
      int? pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId == null) return;
      await apiService.updateCarrierLocation(
        pickupCarrierId: pickupCarrierId,
        latitude: carrierLocation!.latitude,
        longitude: carrierLocation!.longitude,
      );
    } catch (_) {}
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _locationStream?.cancel();
  }

  void _openMapForPickupNavigation() {
    final lat = order!.senderAddress?.latitude;
    final lng = order!.senderAddress?.longitude;
    if (lat == null || lng == null || carrierLocation == null) return;
    _launchUrl(
      "https://www.google.com/maps/dir/?api=1&origin=${carrierLocation!.latitude},${carrierLocation!.longitude}&destination=$lat,$lng&travelmode=driving",
    );
  }

  void _openMapForDeliveryNavigation() {
    final lat = order!.receiverAddress?.latitude;
    final lng = order!.receiverAddress?.longitude;
    if (lat == null || lng == null || carrierLocation == null) return;
    _launchUrl(
      "https://www.google.com/maps/dir/?api=1&origin=${carrierLocation!.latitude},${carrierLocation!.longitude}&destination=$lat,$lng&travelmode=driving",
    );
  }

  void _openMapForShopNavigation() {
    if (_shopDropDetails == null || carrierLocation == null) return;
    final shopAddress = _shopDropDetails?['address'];
    final lat = double.tryParse(shopAddress?['latitude']?.toString() ?? "0");
    final lng = double.tryParse(shopAddress?['longitude']?.toString() ?? "0");
    if (lat == null || lng == null) return;
    _launchUrl(
      "https://www.google.com/maps/dir/?api=1&origin=${carrierLocation!.latitude},${carrierLocation!.longitude}&destination=$lat,$lng&travelmode=driving",
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri))
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar("Phone number is empty");
      return;
    }
    String formatted = phoneNumber.trim();
    if (RegExp(r'^\d{10}$').hasMatch(formatted)) formatted = '+91$formatted';
    try {
      await launchUrl(
        Uri.parse('tel:$formatted'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
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
    if (carrierLocation == null || order?.senderAddress?.latitude == null)
      return "0 km";
    final d = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.senderAddress!.latitude!,
      order!.senderAddress!.longitude!,
    );
    return "${(d / 1000).toStringAsFixed(2)} km";
  }

  String _getDeliveryDistance() {
    if (carrierLocation == null || order?.receiverAddress?.latitude == null)
      return "0 km";
    final d = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      order!.receiverAddress!.latitude!,
      order!.receiverAddress!.longitude!,
    );
    return "${(d / 1000).toStringAsFixed(2)} km";
  }

  String _getShopDistance() {
    if (_shopDropDetails == null || carrierLocation == null) return "0 km";
    final shopAddress = _shopDropDetails?['address'];
    final lat = double.tryParse(shopAddress?['latitude']?.toString() ?? "0");
    final lng = double.tryParse(shopAddress?['longitude']?.toString() ?? "0");
    if (lat == null || lng == null) return "0 km";
    final d = Geolocator.distanceBetween(
      carrierLocation!.latitude,
      carrierLocation!.longitude,
      lat,
      lng,
    );
    return "${(d / 1000).toStringAsFixed(2)} km";
  }

  Widget _buildLocationCard() {
    final Color accentColor = isPickupStage
        ? Colors.red.shade700
        : (isShopDropStage ? Colors.orange : Colors.green);

    final String cardTitle = isPickupStage
        ? "Pickup Location"
        : (isShopDropStage ? "Drop Location (Shop)" : "Delivery Location");

    final String cardSubtitle = isPickupStage
        ? "Collect parcel from here"
        : (isShopDropStage
              ? "Deliver to shop first"
              : "Final delivery destination");

    final String personName = isPickupStage
        ? (pickingUpFromShop
              ? (_shopDropDetails?['shop_name'] ??
                    _shopDropDetails?['owner_name'] ??
                    "Shop")
              : (order!.senderAddress?.senderName ?? "Sender"))
        : (isShopDropStage
              ? (_shopDropDetails?['shop_name'] ??
                    _shopDropDetails?['owner_name'] ??
                    "Shop")
              : (order!.receiverAddress?.receiverName ?? "Receiver"));

    final String phoneNumber = isPickupStage
        ? (pickingUpFromShop
              ? (_shopDropDetails?['phone'] ?? "")
              : (order!.senderAddress?.phoneNumber ?? ""))
        : (isShopDropStage
              ? (_shopDropDetails?['phone'] ?? "")
              : (order!.receiverAddress?.phoneNumber ?? ""));

    final String address = isPickupStage
        ? (pickingUpFromShop
              ? (_shopDropDetails?['address']?['address'] ??
                    _shopDropDetails?['address'] ??
                    "")
              : (order!.senderAddress?.address ?? ""))
        : (isShopDropStage
              ? (_shopDropDetails?['address']?['address'] ??
                    _shopDropDetails?['address'] ??
                    "")
              : (order!.receiverAddress?.address ?? ""));

    final String districtState = isPickupStage
        ? (pickingUpFromShop
              ? "${_shopDropDetails?['address']?['district'] ?? ""}, ${_shopDropDetails?['address']?['state'] ?? ""}"
              : "${order!.senderAddress?.district ?? ""}, ${order!.senderAddress?.state ?? ""}")
        : (isShopDropStage
              ? "${_shopDropDetails?['address']?['district'] ?? ""}, ${_shopDropDetails?['address']?['state'] ?? ""}"
              : "${order!.receiverAddress?.district ?? ""}, ${order!.receiverAddress?.state ?? ""}");

    final String zip = isPickupStage
        ? (pickingUpFromShop
              ? (_shopDropDetails?['address']?['zip_code'] ?? "")
              : (order!.senderAddress?.zipCode ?? ""))
        : (isShopDropStage
              ? (_shopDropDetails?['address']?['zip_code'] ?? "")
              : (order!.receiverAddress?.zipCode ?? ""));

    final String distanceLabel = isPickupStage
        ? (pickingUpFromShop ? "Distance to shop" : "Distance to pickup")
        : (isShopDropStage ? "Distance to shop" : "Distance to delivery");

    final String distanceValue = isPickupStage
        ? (pickingUpFromShop ? _getShopDistance() : _getPickupDistance())
        : (isShopDropStage ? _getShopDistance() : _getDeliveryDistance());

    final VoidCallback navigateAction = isPickupStage
        ? (pickingUpFromShop
              ? _openMapForShopNavigation
              : _openMapForPickupNavigation)
        : (isShopDropStage
              ? _openMapForShopNavigation
              : _openMapForDeliveryNavigation);

    final bool showCancelButton = !isPickupVerified;
    final bool showDropOrderButton =
        isPickupVerified && widget.selectedShopDropId == null;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isPickupStage ? Icons.location_pin : Icons.location_on,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      cardSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCancelButton || showDropOrderButton)
                Container(
                  decoration: BoxDecoration(
                    color: showDropOrderButton
                        ? Colors.green
                        : Colors.red.shade700,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isCancelling) {
                        showDropOrderButton
                            ? _showDropLocationConfirmation()
                            : _cancelOrder();
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
                          : Text(
                              showDropOrderButton ? "Drop Order" : "Cancel",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    isShopDropStage ? Icons.store : Icons.person,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _makePhoneCall(phoneNumber),
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
                    child: Icon(Icons.call, color: accentColor, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                      isShopDropStage
                          ? "Shop Address Details"
                          : (isPickupStage
                                ? "Pickup Address"
                                : "Delivery Address"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  districtState,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  "ZIP: $zip",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (carrierLocation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: accentColor, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            distanceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            distanceValue,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: navigateAction,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text("Navigate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
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

  Widget _buildBottomSlider() {
    final bool hasShopDropActive = isShopDropStage;
    debugPrint(
      "🛠️ DEBUG SLIDER: stage=$hasShopDropActive, arrived=$isShopDropArrived, completed=$isShopDropCompleted",
    );

    if (hasShopDropActive) {
      if (isShopDropCompleted) {
        return _buildCompletionCard("Drop Completed ✓", Colors.green);
      }
      if (isShopDropArrived) {
        final bool hasImage = _shopDropDetails?['image'] != null;
        if (hasImage) {
          return _buildCompletionCard(
            "Verify Shop Drop",
            Colors.orange,
            onTap: _showShopDropOtpSheet,
          );
        } else {
          return _buildCompletionCard(
            "Upload Product Image",
            Colors.orange,
            onTap: _showImageUploadSheet,
          );
        }
      }

      if (!isShopDropArrived) {
        return _buildSlider(
          label: "Slide to confirm arrival at drop location",
          color: Colors.orange,
          icon: Icons.store,
          onSlide: _confirmShopDropArrival,
        );
      }

      return const SizedBox.shrink();
    }

    if (isDeliveryCompleted) {
      return _buildCompletionCard("Delivery Completed ✓", Colors.green);
    }

    if (isDeliveryArrived && !isDeliveryCompleted) {
      return _buildCompletionCard(
        "Verify Delivery",
        Colors.green,
        onTap: () => _showDeliveryOtpSheet(),
      );
    }

    if (isPickupVerified && !isDeliveryArrived) {
      return _buildSlider(
        label: "Slide to confirm delivery arrival",
        color: Colors.green,
        icon: Icons.check,
        onSlide: _markDeliveryArrived,
      );
    }

    if (isPickupArrived && !isPickupVerified) {
      return _buildCompletionCard(
        pickingUpFromShop ? "Verify Shop Pickup" : "Verify Pickup",
        Colors.green,
        onTap: () => _showPickupOtpSheet(),
      );
    }

    return _buildSlider(
      label: pickingUpFromShop
          ? "Slide to confirm arrival at shop"
          : "Slide to confirm pickup arrival",
      color: Colors.red.shade700,
      icon: pickingUpFromShop ? Icons.store : Icons.arrow_forward,
      onSlide: _markPickupArrived,
    );
  }

  Future<void> _loadOrderDetails() async {
    setState(() => isLoading = true);
    try {
      final fetchedOrder = await apiService.fetchOrderById(widget.orderId);
      if (mounted && fetchedOrder != null) {
        setState(() {
          order = fetchedOrder;
          isLoading = false;
        });
        await ApiService.saveActiveOrder(widget.orderId);
      } else {
        if (mounted) setState(() => isLoading = false);
        _showErrorSnackBar("Order not found");
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
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
              if (mounted)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CarrierDashboard()),
                  (route) => false,
                );
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

  Widget _sheetHandle() => Container(
    margin: const EdgeInsets.only(top: 12),
    width: 50,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sheetIcon(IconData icon, Color bg, Color fg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Icon(icon, color: fg, size: 40),
  );

  Widget _contactCard(
    Color bg,
    IconData icon,
    Color iconColor,
    String name,
    String phone,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                phone,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sentRow() => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.check_circle, size: 20, color: Colors.white),
      SizedBox(width: 8),
      Text(
        "OTP Sent Successfully",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    ],
  );

  Widget _loadingIndicator() => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );

  Widget _otpEntryCard({
    required TextEditingController controller,
    required Color focusColor,
    required String timerText,
    required bool timerActive,
    required Future<void> Function() onResend,
    required void Function(String) onCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Enter 6-digit OTP",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Pinput(
            controller: controller,
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
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 50,
              height: 55,
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: focusColor,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: focusColor, width: 2),
                borderRadius: BorderRadius.circular(12),
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
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onCompleted: onCompleted,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive OTP? ",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: timerActive ? null : onResend,
                child: Text(
                  timerText,
                  style: TextStyle(
                    color: timerActive ? Colors.grey : focusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required Color color,
    required IconData icon,
    required Future<void> Function() onSlide,
  }) {
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
            await onSlide();
            return true;
          },
          buttonColor: color,
          backgroundColor: Colors.grey.shade100,
          highlightedColor: Colors.white,
          baseColor: color,
          label: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          icon: Center(child: Icon(icon, color: Colors.white, size: 24)),
          width: MediaQuery.of(context).size.width - 40,
          height: 60,
          radius: 30,
          vibrationFlag: true,
          shimmer: true,
        ),
      ),
    );
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
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : order == null
            ? _buildErrorWidget()
            : Column(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
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
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
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
                  Expanded(child: _buildLocationCard()),
                ],
              ),
        bottomSheet: _buildBottomSlider(),
      ),
    );
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _otpController.dispose();
    super.dispose();
  }
}
