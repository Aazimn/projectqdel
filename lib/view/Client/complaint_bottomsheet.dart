import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/complaint_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:logger/logger.dart';

class ComplaintBottomSheet extends StatefulWidget {
  final int? pickupId;
  final String orderId;
  final String productName;
  final Map<String, dynamic> orderData; 

  const ComplaintBottomSheet({
    super.key,
    this.pickupId,
    required this.orderId,
    required this.productName,
    required this.orderData, 
  });

  @override
  State<ComplaintBottomSheet> createState() => _ComplaintBottomSheetState();
}

class _ComplaintBottomSheetState extends State<ComplaintBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<int?> _getValidPickupDetailsId() async {
    _logger.i('🔍 Extracting valid ID from order data');
    _logger.i('📦 Order data keys: ${widget.orderData.keys}');
    try {
      _logger.i('🔍 Checking SharedPreferences for pickup_carrier_id');
      final pickupCarrierId = await ApiService.getPickupCarrierId();
      if (pickupCarrierId != null && pickupCarrierId > 0) {
        _logger.i(
          '✅ Using pickup_carrier_id from SharedPreferences: $pickupCarrierId',
        );
        return pickupCarrierId;
      }
      if (widget.orderData['shipment_status'] != null) {
        _logger.i(
          '🔍 Checking shipment_status: ${widget.orderData['shipment_status']}',
        );
        final shipment = widget.orderData['shipment_status'] as Map?;

        if (shipment != null) {
          if (shipment['pickup_carrier_id'] != null) {
            final id = shipment['pickup_carrier_id'];
            _logger.i('✅ Found pickup_carrier_id in shipment: $id');
            if (id is int && id > 0) return id;
          }
          if (shipment['carrier'] != null) {
            final carrierId = shipment['carrier'];
            _logger.i('✅ Found carrier in shipment: $carrierId');
            if (carrierId is int && carrierId > 0) return carrierId;
          }
        }
      }
      _logger.i('🔍 Checking direct id field: ${widget.orderData['id']}');
      if (widget.orderData['id'] != null) {
        final id = widget.orderData['id'];
        if (id is int && id > 0) {
          _logger.w('⚠️ Using order ID as fallback: $id');
          return id;
        }
      }
      _logger.e('❌ No valid pickup_carrier_id found');
      return null;
    } catch (e) {
      _logger.e('❌ Error extracting ID: $e');
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    _logger.i('🚀 Submit complaint button pressed');
    if (!_formKey.currentState!.validate()) {
      _logger.w('❌ Form validation failed');
      return;
    }
    final validPickupId = await _getValidPickupDetailsId(); 
    if (validPickupId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit complaint: No carrier assigned to this order yet',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      _logger.i('📤 Creating complaint model...');
      final complaint = ComplaintModel(
        pickupDetails: validPickupId,
        subject: _subjectController.text,
        description: _descriptionController.text,
        orderId: widget.orderId,
        complaintType: 'Customer Complaint',
      );

      _logger.i('📦 Complaint model created: ${complaint.toJson()}');
      _logger.i('🌐 Calling API service...');
      final response = await _apiService.submitComplaint(complaint);
      _logger.i('✅ API response received: $response');
      if (mounted) {
        _logger.i('🔙 Closing bottom sheet with success');
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Error submitting complaint',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains('pickup_details') ||
            errorMessage.contains('Invalid pk')) {
          errorMessage = 'Invalid carrier reference. Please try again.';
        }
        _logger.w('⚠️ Showing error message: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errorMessage'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        _logger.i('🔄 Resetting submitting state');
        setState(() => _isSubmitting = false);
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Submit Complaint',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _logger.i('❌ Bottom sheet closed by user');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: ColorConstants.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order: ${widget.orderId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.productName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subject *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Brief subject of your complaint',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Please describe your issue in detail...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          if (value.length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _submitComplaint(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Submit Complaint',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
