import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/carrier_upload.dart';
import 'package:projectqdel/view/login_screen.dart';
import 'package:projectqdel/view/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  final String phone;
  const RegistrationScreen({super.key, required this.phone});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  int? selectedCountryId;
  int? selectedStateId;
  int? selectedDistrictId;
  List allStates = [];
  List allDistricts = [];

  List countries = [];
  List states = [];
  List districts = [];
  Map<int, List> stateCache = {};
  Map<int, List> districtCache = {};

  Future<void> loadCountries() async {
    try {
      print("Calling countries API...");
      final data = await apiService.getCountries();
      print("Countries response: $data");

      setState(() {
        countries = data;
      });

      print("Countries length after setState: ${countries.length}");
    } catch (e) {
      print("Error loading countries: $e");
    }
  }

  String _customertype = '';

  final _formkey = GlobalKey<FormState>();
  ApiService apiService = ApiService();

  @override
  void dispose() {
    super.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await ApiService.loadSession();
    await loadCountries();
  }

  Future<void> register() async {
    if (!_formkey.currentState!.validate()) return;

    if (_customertype.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select user type")));
      return;
    }

    if (_customertype == 'client') {
      await _registerUser();
    } else if (_customertype == 'carrier') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarrierUploadScreen(
            registrationData: CarrierRegistrationData(
              phone: widget.phone,
              firstname: _firstName.text.trim(),
              lastname: _lastName.text.trim(),
              email: _email.text.trim(),
              userType: _customertype,
              countryId: selectedCountryId,
              stateId: selectedStateId,
              districtId: selectedDistrictId,
              isExistingUser: false,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _registerUser() async {
    bool status = await apiService.registration(
      firstname: _firstName.text.trim(),
      lastname: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: widget.phone,
      userType: _customertype,
      countryId: selectedCountryId,
      stateId: selectedStateId,
      districtId: selectedDistrictId,
    );

    if (status) {
      await ApiService.saveSession(
        token: ApiService.accessToken!,
        userType: "client",
        approvalStatus: "approved",
        phone: widget.phone,
        firstTime: false,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('country', selectedCountryId!);
      await prefs.setInt('state', selectedStateId!);
      await prefs.setInt('district', selectedDistrictId!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful")));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.grey,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome To QDEL!",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text("+91 - ", style: TextStyle(fontSize: 18)),
                                Text(
                                  widget.phone,
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(width: 15),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "change",
                                    style: TextStyle(
                                      color: ColorConstants.deeporange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _firstName,
                              decoration: InputDecoration(
                                filled: true,
                                prefixIcon: Icon(Icons.person),
                                hintText: "First Name",
                                fillColor: ColorConstants.textfieldgrey,
                                focusColor: ColorConstants.blue,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "First name is required";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _lastName,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                filled: true,
                                hintText: "Last Name",
                                fillColor: ColorConstants.textfieldgrey,
                                focusColor: ColorConstants.blue,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Last name is required";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _email,
                              decoration: InputDecoration(
                                filled: true,
                                hintText: "Email",
                                prefixIcon: Icon(Icons.email),
                                fillColor: ColorConstants.textfieldgrey,
                                focusColor: ColorConstants.blue,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email is required";
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}',
                                ).hasMatch(value)) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Column(
                              children: [
                                Text(
                                  "Countries loaded: ${countries.length}",
                                  style: const TextStyle(
                                    color: ColorConstants.red,
                                  ),
                                ),

                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: selectedCountryId,
                                  hint: const Text("Select Country"),
                                  items: countries.map<DropdownMenuItem<int>>((
                                    c,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: c['id'],
                                      child: Text(c['name'].toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) async {
                                    if (value == null) return;

                                    setState(() {
                                      selectedCountryId = value;
                                      selectedStateId = null;
                                      selectedDistrictId = null;

                                      states = [];
                                      districts = [];
                                    });
                                    final data = await apiService.getStates(
                                      countryId: value,
                                    );
                                    print("STATES API RESULT: $data");

                                    if (!stateCache.containsKey(value)) {
                                      final data = await apiService.getStates(
                                        countryId: value,
                                      );
                                      stateCache[value] = data;
                                    }

                                    setState(() {
                                      final selectedCountryName = countries
                                          .firstWhere(
                                            (c) => c['id'] == value,
                                          )['name'];

                                      states = stateCache[value]!
                                          .where(
                                            (s) =>
                                                s['country'] ==
                                                selectedCountryName,
                                          )
                                          .toList();
                                    });
                                  },
                                ),
                                DropdownButtonFormField<int>(
                                  value: selectedStateId,
                                  hint: const Text("Select State"),
                                  items: selectedCountryId == null
                                      ? []
                                      : states.map<DropdownMenuItem<int>>((s) {
                                          return DropdownMenuItem<int>(
                                            value: s['id'],
                                            child: Text(s['name']),
                                          );
                                        }).toList(),
                                  onChanged: (value) async {
                                    if (value == null) return;

                                    setState(() {
                                      selectedStateId = value;
                                      selectedDistrictId = null;
                                      districts = [];
                                    });

                                    if (!districtCache.containsKey(value)) {
                                      final data = await apiService
                                          .getDistricts(stateId: value);
                                      districtCache[value] = data;
                                    }

                                    final selectedStateName = states.firstWhere(
                                      (s) => s['id'] == value,
                                    )['name'];

                                    setState(() {
                                      districts = districtCache[value]!
                                          .where(
                                            (d) =>
                                                d['state_name'] ==
                                                selectedStateName,
                                          )
                                          .toList();
                                    });
                                  },
                                ),
                                DropdownButtonFormField<int>(
                                  value: selectedDistrictId,
                                  hint: Text(
                                    selectedStateId == null
                                        ? "Select State First"
                                        : districts.isEmpty
                                        ? "No district added yet"
                                        : "Select District",
                                  ),
                                  items: selectedStateId == null
                                      ? []
                                      : districts.map<DropdownMenuItem<int>>((
                                          d,
                                        ) {
                                          return DropdownMenuItem<int>(
                                            value: d['id'],
                                            child: Text(d['name']),
                                          );
                                        }).toList(),
                                  onChanged: selectedStateId == null
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedDistrictId = value;
                                          });
                                        },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Select your User Type",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Radio(
                                      value: 'client',
                                      groupValue: _customertype,
                                      onChanged: (value) {
                                        setState(() {
                                          _customertype = value!;
                                        });
                                      },
                                    ),
                                    Text(
                                      'client',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Radio(
                                      value: 'carrier',
                                      groupValue: _customertype,
                                      onChanged: (value) {
                                        setState(() {
                                          _customertype = value!;
                                        });
                                      },
                                    ),
                                    Text(
                                      'carrier',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                                if (_customertype.isEmpty)
                                  const Text(
                                    "Please select a user type",
                                    style: TextStyle(color: ColorConstants.red),
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  child: Container(
                                    height: 40,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: ColorConstants.red,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Register",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ColorConstants.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    register();
                                  },
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
            ),
          ),
        ),
      ),
    );
  }
}
