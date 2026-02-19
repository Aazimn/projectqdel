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
  final _formkey = GlobalKey<FormState>();
  ApiService apiService = ApiService();
  bool _isVerifying = false;

  @override
  void dispose() {
    super.dispose();
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    c6.dispose();
  }

  Future<void> otp() async {
  if (_isVerifying) return;

  setState(() => _isVerifying = true);

  try {
    final fullotp =
        c1.text + c2.text + c3.text + c4.text + c5.text + c6.text;

    if (fullotp.length != 6) return;

    final Map<String, dynamic>? data =
        await apiService.otp(phone: widget.phone, otp: fullotp);

    if (data == null) {
      throw Exception("OTP failed");
    }

    final bool isFirstTime = data['first_time'] == true;

    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(phone: widget.phone),
        ),
      );
      return;
    }

    final accessToken = data['access'];
    final user = data['user'];

    if (accessToken == null || user == null) {
      throw Exception("Invalid session data");
    }

    await ApiService.saveSession(
  token: data['access'],
  userType: data['user']['user_type']
      .toString()
      .toLowerCase(),
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
    debugPrint("OTP ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey,
      body: Form(
        key: _formkey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                color: ColorConstants.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "OTP Verification",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 50,
                      children: [
                        Row(
                          children: [
                            Text(
                              "OTP sent to ",
                              style: TextStyle(fontSize: 20),
                            ),
                            Text(
                              widget.phone,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "change",
                            style: TextStyle(
                              color: ColorConstants.deeporange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _otpBox(
                          controller: c1,
                          autoFocus: true,
                          context: context,
                          index: 0,
                          onCompleted: otp,
                        ),
                        const SizedBox(width: 8),
                        _otpBox(
                          controller: c2,
                          autoFocus: false,
                          context: context,
                          index: 1,
                          onCompleted: otp,
                        ),
                        const SizedBox(width: 8),
                        _otpBox(
                          controller: c3,
                          autoFocus: false,
                          context: context,
                          index: 2,
                          onCompleted: otp,
                        ),
                        const SizedBox(width: 8),
                        _otpBox(
                          controller: c4,
                          autoFocus: false,
                          context: context,
                          index: 3,
                          onCompleted: otp,
                        ),
                        const SizedBox(width: 8),
                        _otpBox(
                          controller: c5,
                          autoFocus: false,
                          context: context,
                          index: 4,
                          onCompleted: otp,
                        ),
                        const SizedBox(width: 8),
                        _otpBox(
                          controller: c6,
                          autoFocus: false,
                          context: context,
                          index: 5,
                          onCompleted: otp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _otpBox({
  required TextEditingController controller,
  required bool autoFocus,
  required BuildContext context,
  required int index,
  required VoidCallback onCompleted,
}) {
  return Container(
    width: 40,
    height: 50,
    decoration: BoxDecoration(
      color: ColorConstants.textfieldgrey,
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: controller,
      autofocus: autoFocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: "",
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          if (index == 5) {
            FocusScope.of(context).unfocus();
            onCompleted();
          } else {
            FocusScope.of(context).nextFocus();
          }
        }
      },
    ),
  );
}
