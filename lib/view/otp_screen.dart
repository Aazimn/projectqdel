import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/registration_screen.dart';
import 'package:projectqdel/view/splash_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();
  final c5 = TextEditingController();
  final c6 = TextEditingController();

  final ApiService apiService = ApiService();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();
  final f5 = FocusNode();
  final f6 = FocusNode();
  FocusNode? _currentFocusedField;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    f1.addListener(_onFocusChange);
    f2.addListener(_onFocusChange);
    f3.addListener(_onFocusChange);
    f4.addListener(_onFocusChange);
    f5.addListener(_onFocusChange);
    f6.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      if (f1.hasFocus) {
        _currentFocusedField = f1;
      } else if (f2.hasFocus) {
        _currentFocusedField = f2;
      } else if (f3.hasFocus) {
        _currentFocusedField = f3;
      } else if (f4.hasFocus) {
        _currentFocusedField = f4;
      } else if (f5.hasFocus) {
        _currentFocusedField = f5;
      } else if (f6.hasFocus) {
        _currentFocusedField = f6;
      } else {
        _currentFocusedField = null;
      }
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_currentFocusedField != null) {
        if (_currentFocusedField == f2 && c2.text.isEmpty) {
          f1.requestFocus();
        } else if (_currentFocusedField == f3 && c3.text.isEmpty) {
          f2.requestFocus();
        } else if (_currentFocusedField == f4 && c4.text.isEmpty) {
          f3.requestFocus();
        } else if (_currentFocusedField == f5 && c5.text.isEmpty) {
          f4.requestFocus();
        } else if (_currentFocusedField == f6 && c6.text.isEmpty) {
          f5.requestFocus();
        }
      }
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendSeconds = 60;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _resendSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    c6.dispose();

    f1.removeListener(_onFocusChange);
    f2.removeListener(_onFocusChange);
    f3.removeListener(_onFocusChange);
    f4.removeListener(_onFocusChange);
    f5.removeListener(_onFocusChange);
    f6.removeListener(_onFocusChange);

    f1.dispose();
    f2.dispose();
    f3.dispose();
    f4.dispose();
    f5.dispose();
    f6.dispose();

    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_isResending || !_canResend) return;

    setState(() => _isResending = true);

    try {
      final success = await apiService.login(phone: widget.phone);

      if (success) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("Failed to resend OTP");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> otp() async {
    if (_isVerifying) return;
    final fullOtp = c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;
    if (fullOtp.length != 6) return;
    setState(() => _isVerifying = true);

    try {
      final data = await apiService.otp(phone: widget.phone, otp: fullOtp);

      if (data == null) throw Exception("OTP failed");

      if (data['first_time'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(phone: widget.phone),
          ),
        );
        return;
      }

      await ApiService.saveSession(
        token: data['access'],
        userType: data['user']['user_type'].toString().toLowerCase(),
        approvalStatus: data['user']['approval_status'] ?? "pending",
        phone: data['user']['phone'],
        firstTime: data['first_time'] ?? false,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _onOtpChanged(
    String value,
    int index, {
    required FocusNode currentFocus,
    required FocusNode? nextFocus,
    required FocusNode? prevFocus,
  }) {
    if (value.isNotEmpty) {
      if (nextFocus != null) {
        nextFocus.requestFocus();
      } else {
        currentFocus.unfocus();
        otp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _handleKeyPress,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/image_assets/qdel_bgg.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.22,
                left: 10,
                right: 10,
                child: Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Image.asset(
                      "assets/image_assets/qdel_boyy.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _header(context),
                  _bottomOtpSheet(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: ColorConstants.red,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 130,
              width: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColorConstants.red, width: 6),
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/image_assets/logo_qdel.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomOtpSheet() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "OTP Verification",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      "OTP sent to ",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Change",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _otpBox(
                      controller: c1,
                      focusNode: f1,
                      nextFocus: f2,
                      prevFocus: null,
                      index: 0,
                    ),
                    _otpBox(
                      controller: c2,
                      focusNode: f2,
                      nextFocus: f3,
                      prevFocus: f1,
                      index: 1,
                    ),
                    _otpBox(
                      controller: c3,
                      focusNode: f3,
                      nextFocus: f4,
                      prevFocus: f2,
                      index: 2,
                    ),
                    _otpBox(
                      controller: c4,
                      focusNode: f4,
                      nextFocus: f5,
                      prevFocus: f3,
                      index: 3,
                    ),
                    _otpBox(
                      controller: c5,
                      focusNode: f5,
                      nextFocus: f6,
                      prevFocus: f4,
                      index: 4,
                    ),
                    _otpBox(
                      controller: c6,
                      focusNode: f6,
                      nextFocus: null,
                      prevFocus: f5,
                      index: 5,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_canResend)
                      Text(
                        'Resend OTP in $_resendSeconds seconds',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )
                    else if (_isResending)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (_isVerifying)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required FocusNode? prevFocus,
    required int index,
  }) {
    return Container(
      width: 42,
      height: 50,
      decoration: BoxDecoration(
        color: ColorConstants.textfieldgrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: "",
        ),
        onChanged: (value) {
          _onOtpChanged(
            value,
            index,
            currentFocus: focusNode,
            nextFocus: nextFocus,
            prevFocus: prevFocus,
          );
        },
      ),
    );
  }
}
