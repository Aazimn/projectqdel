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

  // Simple dummy country codes - no API needed
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

  String selectedCode = "+91"; // Default selection

  // Remove fetchCountries or keep it but don't use it for dropdown
  Future<void> fetchCountries() async {
    // Optional: You can still call this if needed for other purposes
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
    fetchCountries(); // Optional: keep if needed elsewhere
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: isError ? SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  Future<void> _login() async {
    // Check if mounted before proceeding
    if (!mounted) return;

    // Validate form
    if (!_formkey.currentState!.validate()) {
      return;
    }

    // Check if phone number is valid
    if (phonectrl.text.trim().length != 10) {
      _showSnackBar("Please enter a valid 10-digit phone number", isError: true);
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Call login API
      bool status = await apiService.login(phone: phonectrl.text.trim());

      // Check if widget is still mounted
      if (!mounted) return;

      if (status) {
        // Show success message
        _showSnackBar("OTP sent successfully!");
        
        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(phone: phonectrl.text.trim()),
          ),
        );
      } else {
        // Check for rate limiting or other errors
        _showSnackBar(
          "Failed to send OTP. Please try again later.",
          isError: true,
        );
      }
    } catch (e) {
      // Handle any exceptions
      if (!mounted) return;
      
      String errorMessage = "An error occurred. Please try again.";
      
      // Check for rate limiting (status code 429)
      if (e.toString().contains("429") || e.toString().contains("rate limit")) {
        errorMessage = "Too many attempts. Please wait before requesting OTP again.";
      }
      
      _showSnackBar(errorMessage, isError: true);
    } finally {
      // Reset loading state if widget is still mounted
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
        child: SafeArea(
          child: Form(
            key: _formkey,
            child: Stack(
              children: [
                Positioned(
                  top: 290,
                  left: 20,
                  child: Container(
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
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 20)),
                          Text(
                            "QDEL",
                            style: TextStyle(
                              color: ColorConstants.red,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _bottomLoginSheet(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
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