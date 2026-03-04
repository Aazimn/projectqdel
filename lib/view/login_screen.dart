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

  @override
  void dispose() {
    super.dispose();
    phonectrl.dispose();
  }

  List<dynamic> countries = [];
  bool isLoadingCountries = true;
  String? selectedCode = "+91";

  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  Future<void> fetchCountries() async {
    try {
      final data = await apiService.countriesList();

      setState(() {
        countries = data;
        isLoadingCountries = false;

        // Default select first country code
        if (countries.isNotEmpty) {
          selectedCode = "+${countries.first['code']}";
        }
      });
    } catch (e) {
      isLoadingCountries = false;
      debugPrint("Error loading country codes: $e");
    }
  }

  Future<bool> _login() async {
    if (_formkey.currentState!.validate()) {
      bool status = await apiService.login(phone: phonectrl.text.trim());
      if (status) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Success")));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(phone: phonectrl.text.trim()),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("failed")));
        return false;
      }
    }
    return false;
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
                // Positioned(
                //   bottom: 315,
                //   right: 68,
                //   child: Container(
                //     height: 50,
                //     width: 50,
                //     // color: Colors.white,
                //     child: Image.asset(
                //       "assets/image_assets/logo_qdel.png",
                //       fit: BoxFit.contain,
                //     ),
                //   ),
                // ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          Padding(padding: EdgeInsetsGeometry.only(top: 20)),
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
                        // Container(
                        //   height: 300,
                        //   width: 300,
                        //   child: Image.asset(
                        //     "assets/image_assets/qdel_boyy.png",
                        //     fit: BoxFit.contain,
                        //   ),
                        // ),
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
      // curve: Curves.easeOut,
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

        // ✅ KEY FIX
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ very important
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

                if (isValidPhone)
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
          items: const [
            DropdownMenuItem(
              value: "+91",
              child: Center(
                child: Text(
                  "+91",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DropdownMenuItem(
              value: "+1",
              child: Center(
                child: Text(
                  "+1",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DropdownMenuItem(
              value: "+44",
              child: Center(
                child: Text(
                  "+44",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DropdownMenuItem(
              value: "+61",
              child: Center(
                child: Text(
                  "+61",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => selectedCode = v!),
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
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
