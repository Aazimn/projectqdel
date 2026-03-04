import 'package:flutter/material.dart';
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

  final f1 = FocusNode();
  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();
  final f5 = FocusNode();
  final f6 = FocusNode();

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    c6.dispose();

    f1.dispose();
    f2.dispose();
    f3.dispose();
    f4.dispose();
    f5.dispose();
    f6.dispose();

    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/image_assets/qdel_bgg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              /// Boy Image (same as login)
              Positioned(
                top: 290,
                left: 20,
                child: SizedBox(
                  height: 300,
                  width: 300,
                  child: Image.asset(
                    "assets/image_assets/qdel_boyy.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      "QDEL",
                      style: TextStyle(
                        color: ColorConstants.red,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _bottomOtpSheet(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔴 Bottom OTP Sheet (same style as login)
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

                const SizedBox(height: 24),

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
          if (value.isNotEmpty) {
            if (nextFocus != null) {
              nextFocus.requestFocus();
            } else {
              focusNode.unfocus();
              otp(); // auto verify
            }
          } else {
            // 👈 BACKSPACE HANDLING
            if (prevFocus != null) {
              prevFocus.requestFocus();
            }
          }
        },
      ),
    );
  }
}
