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
  String selectedCode = "+91";
  String lang = "English";
  ApiService apiService = ApiService();
  bool isValidPhone = false;

  @override
  void dispose() {
    super.dispose();
    phonectrl.dispose();
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
      body: SafeArea(
        child: Form(
          key: _formkey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsetsGeometry.all(10)),
                    Row(
                      children: [
                        Padding(padding: EdgeInsetsGeometry.only(left: 20)),
                        Text(
                          "Let's get start",
                          style: TextStyle(
                            color: ColorConstants.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 25),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: ColorConstants.black,
                           
                            alignment: Alignment.center,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: ColorConstants.white,
                            ),
                            value: lang,
                            items: [
                              DropdownMenuItem(
                                value: "English",
                                child: Center(child: Text("English")),
                              ),
                              DropdownMenuItem(
                                value: "Hindi",
                                child: Center(child: Text("Hindi")),
                              ),
                              DropdownMenuItem(
                                value: "Malayalam",
                                child: Center(child: Text("Malayalam")),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                lang = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsetsGeometry.only(left: 20)),
                        Text(
                          "Access our services with a valid phone number.",

                          style: TextStyle(
                            color: ColorConstants.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 45,
                          width: 120,
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCode,
                              isExpanded: true,
                              alignment: Alignment.center,
                              icon: const Icon(Icons.arrow_drop_down),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "+91",
                                  child: Center(
                                    child: Text(
                                      "+91",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "+1",
                                  child: Center(
                                    child: Text(
                                      "+1",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "+44",
                                  child: Center(
                                    child: Text(
                                      "+44",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "+61",
                                  child: Center(
                                    child: Text(
                                      "+61",
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedCode = value!;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          height: 45,
                          width: 160,
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            controller: phonectrl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: "00000000",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone number required";
                              }
                              if (value.length != 10) {
                                return "Enter 10 digit number";
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                isValidPhone = value.length == 10;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (isValidPhone)
                      GestureDetector(
                        onTap: _login,
                        child: Container(
                          height: 30,
                          width: 80,
                          decoration: BoxDecoration(
                            color: ColorConstants.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Next",
                              style: TextStyle(
                                color: ColorConstants.black,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
