import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class ChangePhoneSheet extends StatefulWidget {
  const ChangePhoneSheet({super.key});

  @override
  State<ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<ChangePhoneSheet> {
  final ApiService _apiService = ApiService();

  // Step tracking
  int _currentStep =
      1; // 1: Enter new number, 2: Verify old OTP, 3: Verify new OTP

  // Controllers
  final _newPhoneController = TextEditingController();
  final _oldOtpController = TextEditingController();
  final _newOtpController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _newPhoneEntered = false;
  bool _oldOtpSent = false;
  bool _oldOtpVerified = false;
  bool _newOtpSent = false;

  // Store OTPs from response for debugging/display
  String? _oldOtpFromResponse;
  String? _newOtpFromResponse;

  // Timers for resend
  int _oldResendSeconds = 0;
  int _newResendSeconds = 0;
  Timer? _oldTimer;
  Timer? _newTimer;

  @override
  void dispose() {
    _newPhoneController.dispose();
    _oldOtpController.dispose();
    _newOtpController.dispose();
    _oldTimer?.cancel();
    _newTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer(bool isOld) {
    if (isOld) {
      setState(() => _oldResendSeconds = 30);
      _oldTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_oldResendSeconds <= 1) {
          timer.cancel();
          setState(() => _oldResendSeconds = 0);
        } else {
          setState(() => _oldResendSeconds--);
        }
      });
    } else {
      setState(() => _newResendSeconds = 30);
      _newTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_newResendSeconds <= 1) {
          timer.cancel();
          setState(() => _newResendSeconds = 0);
        } else {
          setState(() => _newResendSeconds--);
        }
      });
    }
  }

  // Step 1: Enter new phone number and send OTP to old number
  Future<void> _enterNewNumber() async {
    if (_newPhoneController.text.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit phone number',
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.sendOldPhoneOtp(
        newPhone: _newPhoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _newPhoneEntered = true;
          _oldOtpSent = true;
          _currentStep = 2;
          _isLoading = false;
          // Store OTP from response if needed for debugging
          _oldOtpFromResponse = response['otp_old']?.toString();
        });
        _startResendTimer(true);
        _showSnackBar('OTP sent to your registered number', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to send OTP: $e', Colors.red);
      }
    }
  }

  // Step 2: Verify OTP sent to old number
  Future<void> _verifyOldOtp() async {
    if (_oldOtpController.text.length != 6) {
      _showSnackBar('Please enter 6-digit OTP', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.verifyOldPhoneOtp(
        newPhone: _newPhoneController.text.trim(),
        otp: _oldOtpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _oldOtpVerified = true;
          _currentStep = 3;
          _isLoading = false;
        });
        _oldTimer?.cancel();
        _showSnackBar('Old phone verified successfully', Colors.green);

        // Automatically send OTP to new number
        _sendNewOtp();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Invalid OTP: $e', Colors.red);
      }
    }
  }

  // Send OTP to new number
  Future<void> _sendNewOtp() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.sendNewPhoneOtp(
        newPhone: _newPhoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _newOtpSent = true;
          _isLoading = false;
          // Store OTP from response if needed for debugging
          _newOtpFromResponse = response['otp_new']?.toString();
        });
        _startResendTimer(false);
        _showSnackBar('OTP sent to new number', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to send OTP: $e', Colors.red);
      }
    }
  }

  // Step 3: Verify OTP sent to new number
  Future<void> _verifyNewOtp() async {
    if (_newOtpController.text.length != 6) {
      _showSnackBar('Please enter 6-digit OTP', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.verifyNewPhoneOtp(
        newPhone: _newPhoneController.text.trim(),
        otp: _newOtpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _currentStep = 4;
          _isLoading = false;
        });
        _newTimer?.cancel();

        // Show success and close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Invalid OTP: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: ColorConstants.red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(1, 'Enter New'),
                Expanded(
                  child: Divider(
                    color: _currentStep > 1 ? Colors.red : Colors.grey,
                  ),
                ),
                _buildStepIndicator(2, 'Verify Old'),
                Expanded(
                  child: Divider(
                    color: _currentStep > 2 ? Colors.red : Colors.grey,
                  ),
                ),
                _buildStepIndicator(3, 'Verify New'),
              ],
            ),
          ),

          // Content based on step
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: ColorConstants.red),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                ? ColorConstants.red
                : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? ColorConstants.red : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Enter New Number';
      case 2:
        return 'Verify Old Number';
      case 3:
        return 'Verify New Number';
      case 4:
        return 'Success!';
      default:
        return 'Change Phone';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildEnterNumberStep();
      case 2:
        return _buildVerifyOldStep();
      case 3:
        return _buildVerifyNewStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEnterNumberStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Enter Your New Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your new phone number. We\'ll send a verification code to your current number.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _newPhoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: 'New Phone Number',
            hintText: '10-digit mobile number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ColorConstants.red, width: 2),
            ),
            prefixIcon: const Icon(Icons.phone_outlined),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('+91 '),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: ElevatedButton(
            onPressed: _enterNewNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.red,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Send OTP',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyOldStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Verify Your Current Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a verification code to your registered number.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        // if (_oldOtpFromResponse != null) ...[
        //   const SizedBox(height: 4),
        //   Container(
        //     padding: const EdgeInsets.all(8),
        //     decoration: BoxDecoration(
        //       color: Colors.blue.shade50,
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: Text(
        //       'Debug: OTP is ${_oldOtpFromResponse}',
        //       style: const TextStyle(color: Colors.blue, fontSize: 12),
        //     ),
        //   ),
        // ],
        const SizedBox(height: 24),

        TextField(
          controller: _oldOtpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Enter 6-digit OTP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ColorConstants.red, width: 2),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _verifyOldOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify OTP',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_oldResendSeconds > 0)
          Center(
            child: Text(
              'Resend OTP in $_oldResendSeconds seconds',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          Center(
            child: TextButton(
              onPressed: _enterNewNumber,
              child: const Text(
                'Resend OTP',
                style: TextStyle(color: ColorConstants.red),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerifyNewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Verify Your New Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a verification code to your new number: ${_newPhoneController.text}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        // if (_newOtpFromResponse != null) ...[
        //   const SizedBox(height: 4),
        //   Container(
        //     padding: const EdgeInsets.all(8),
        //     decoration: BoxDecoration(
        //       color: Colors.blue.shade50,
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: Text(
        //       'Debug: OTP is ${_newOtpFromResponse}',
        //       style: const TextStyle(color: Colors.blue, fontSize: 12),
        //     ),
        //   ),
        // ],
        const SizedBox(height: 24),

        TextField(
          controller: _newOtpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Enter 6-digit OTP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ColorConstants.red, width: 2),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _verifyNewOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify & Update',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_newResendSeconds > 0)
          Center(
            child: Text(
              'Resend OTP in $_newResendSeconds seconds',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          Center(
            child: TextButton(
              onPressed: _sendNewOtp,
              child: const Text(
                'Resend OTP',
                style: TextStyle(color: ColorConstants.red),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 24),
          const Text(
            'Phone Number Updated Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your phone number has been changed to\n${_newPhoneController.text}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
