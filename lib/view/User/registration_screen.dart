import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/splash_screen.dart';

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

  List countries = [];
  List states = [];
  List districts = [];

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
    loadCountries();
  }

  Future<void> register() async {
    if (!_formkey.currentState!.validate()) {
      return;
    }

    if (_customertype.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select user type")));
      return;
    }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration successful")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
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
                                Text(
                                  "change",
                                  style: TextStyle(
                                    color: ColorConstants.deeporange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
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
                                  value: selectedCountryId,
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
                                      states.clear();
                                      districts.clear();
                                    });

                                    print("Selected country ID: $value");

                                    final data = await apiService.getStates(
                                      countryId: value,
                                    );

                                    print("States response: $data");

                                    setState(() {
                                      states = data ?? [];
                                    });

                                    print("States length: ${states.length}");
                                  },
                                ),
                                DropdownButtonFormField<int>(
                                  value: selectedStateId,
                                  hint: const Text("Select State"),
                                  items: states.map<DropdownMenuItem<int>>((s) {
                                    return DropdownMenuItem<int>(
                                      value: s['id'],
                                      child: Text(s['name']),
                                    );
                                  }).toList(),
                                  onChanged: states.isEmpty
                                      ? null
                                      : (value) async {
                                          setState(() {
                                            selectedStateId = value;
                                            selectedDistrictId = null;
                                            districts.clear();
                                          });

                                          final data = await apiService
                                              .getDistricts(stateId: value!);
                                          setState(() {
                                            districts = data;
                                          });
                                        },
                                ),

                                DropdownButtonFormField<int>(
                                  value: selectedDistrictId,
                                  hint: const Text("Select District"),
                                  items: districts.isEmpty
                                      ? []
                                      : districts.map<DropdownMenuItem<int>>((
                                          d,
                                        ) {
                                          return DropdownMenuItem<int>(
                                            value: d['id'],
                                            child: Text(d['name']),
                                          );
                                        }).toList(),
                                  onChanged: districts.isEmpty
                                      ? null
                                      : (value) {
                                          setState(() {
                                            selectedDistrictId = value;
                                          });
                                        },
                                  validator: (value) => value == null
                                      ? "District required"
                                      : null,
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
