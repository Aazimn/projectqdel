import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController phonectrl = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  String lang = "English";
  ApiService apiService = ApiService();
  bool isValidPhone = false;
  bool _isLoading = false;

  @override
  void dispose() {
    phonectrl.dispose();
    super.dispose();
  }

  final List<Map<String, String>> countryCodes = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'USA', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'UK', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'Pakistan', 'code': '+92', 'flag': '🇵🇰'},
    {'name': 'Bangladesh', 'code': '+880', 'flag': '🇧🇩'},
    {'name': 'Sri Lanka', 'code': '+94', 'flag': '🇱🇰'},
    {'name': 'Nepal', 'code': '+977', 'flag': '🇳🇵'},
    {'name': 'Myanmar', 'code': '+95', 'flag': '🇲🇲'},
  ];

  String selectedCode = "+91";

  Future<void> fetchCountries() async {
    try {
      final data = await apiService.countriesList();
      debugPrint("Countries loaded: $data");
    } catch (e) {
      debugPrint("Error loading country codes: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: isError
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              )
            : null,
      ),
    );
  }

  Future<void> _login() async {
    if (!mounted) return;
    if (!_formkey.currentState!.validate()) {
      return;
    }

    if (phonectrl.text.trim().length != 10) {
      _showSnackBar(
        "Please enter a valid 10-digit phone number",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool status = await apiService.login(phone: phonectrl.text.trim());

      if (!mounted) return;

      if (status) {
        _showSnackBar("OTP sent successfully!");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(phone: phonectrl.text.trim()),
          ),
        );
      } else {
        _showSnackBar(
          "Failed to send OTP. Please try again later.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "An error occurred. Please try again.";

      if (e.toString().contains("429") || e.toString().contains("rate limit")) {
        errorMessage =
            "Too many attempts. Please wait before requesting OTP again.";
      }

      _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/image_assets/qdel_bgg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Form(
          key: _formkey,
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
                children: [_header(context), _bottomLoginSheet()],
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

  Widget _bottomLoginSheet() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 1),
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
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Let's get start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Access our services with a valid phone number.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _countryCode(),
                    const SizedBox(width: 20),
                    _phoneInput(),
                  ],
                ),
                const SizedBox(height: 20),
                if (isValidPhone && !_isLoading)
                  Center(
                    child: GestureDetector(
                      onTap: _login,
                      child: Container(
                        height: 40,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Next",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isLoading)
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

  Widget _countryCode() {
    return Container(
      height: 45,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode,
          isExpanded: true,
          alignment: Alignment.center,
          icon: const Icon(Icons.arrow_drop_down),
          items: countryCodes.map<DropdownMenuItem<String>>((country) {
            return DropdownMenuItem<String>(
              value: country['code'],
              child: Center(
                child: Text(
                  "${country['flag']} ${country['code']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedCode = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _phoneInput() {
    return Container(
      height: 45,
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        controller: phonectrl,
        keyboardType: TextInputType.number,
        maxLength: 10,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          hintText: "0000000000",
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (v) => setState(() => isValidPhone = v.length == 10),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter phone number';
          }
          if (value.length != 10) {
            return 'Phone number must be 10 digits';
          }
          return null;
        },
      ),
    );
  }
}
