import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/login_screen.dart';

class RejectedScreen extends StatefulWidget {
  const RejectedScreen({super.key});

  @override
  State<RejectedScreen> createState() => _RejectedScreenState();
}

class _RejectedScreenState extends State<RejectedScreen> {
  ApiService apiService = ApiService();
  bool isChangingToClient = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> changeToClient() async {
    setState(() {
      isChangingToClient = true;
    });

    try {
      // Call API to change user type to client
      final success = await apiService.updateUserType("client");

      if (success && mounted) {
        // Update local session
        await ApiService.setUserType("client");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully switched to Client mode"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // You can navigate to client home or appropriate screen
        debugPrint("Changed to client type");

        // Optionally navigate to client home screen
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        // );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to switch to Client mode"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isChangingToClient = false;
        });
      }
    }
  }

  void _showContinueAsClientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Continue as Client?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your carrier application was rejected. Would you like to continue as a Client instead?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "As a Client, you can book deliveries without going through carrier verification.",
                      style: TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
              changeToClient();
            },
            child: const Text("Continue as Client"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ACCOUNT STATUS",
                      style: TextStyle(
                        color: Colors.black54,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 70),
              ),

              const SizedBox(height: 30),

              /// Title
              const Text(
                "Account\nRejected",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  "We were unable to verify your information at this time. Please ensure your documents are clear and valid.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue as Client Button Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.switch_account,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Alternative Option",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Continue as Client Button
                    GestureDetector(
                      onTap: isChangingToClient
                          ? null
                          : _showContinueAsClientDialog,
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.redAccent,
                              Colors.red.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isChangingToClient
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Switching...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Continue as Client",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Helper text
                    const Center(
                      child: Text(
                        "Skip carrier verification and use Qdel as a client",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Spacer(),

              // Retry Registration Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () async {
                    await ApiService.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.4),
                          Colors.red.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(color: ColorConstants.black),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.refresh, color: ColorConstants.black),
                        SizedBox(width: 10),
                        Text(
                          "Retry Registration",
                          style: TextStyle(
                            color: ColorConstants.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "PLEASE TRY AGAIN",
                style: TextStyle(
                  color: Colors.black38,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
