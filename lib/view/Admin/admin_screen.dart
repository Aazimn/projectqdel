import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/country_screen.dart';
import 'package:projectqdel/view/Admin/district_screen.dart';
import 'package:projectqdel/view/Admin/state_screen.dart';
import 'package:projectqdel/view/splash_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  ApiService apiService = ApiService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 20),
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "Admin",
            style: TextStyle(
              color: ColorConstants.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        backgroundColor: ColorConstants.red,
        actions: [
          IconButton(
            onPressed: () {
              ApiService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
            icon: Icon(Icons.logout, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 10,
          children: [
            InkWell(
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ColorConstants.red,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Country",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.white,
                        ),
                      ),
                      Icon(
                        Icons.arrow_circle_right,
                        color: ColorConstants.white,
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CountryScreen()),
                );
              },
            ),
            InkWell(
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ColorConstants.red,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit State",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.white,
                        ),
                      ),
                      Icon(
                        Icons.arrow_circle_right,
                        color: ColorConstants.white,
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StateScreen()),
                );
              },
            ),
            InkWell(
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ColorConstants.red,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit District",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.white,
                        ),
                      ),
                      Icon(
                        Icons.arrow_circle_right,
                        color: ColorConstants.white,
                      ),
                    ],
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DistrictScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
