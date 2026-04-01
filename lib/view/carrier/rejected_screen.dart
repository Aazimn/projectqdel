import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/CommonPages/splash_screen.dart';
import 'package:projectqdel/view/Registration/login_screen.dart';


class RejectedScreen extends StatefulWidget {
  final String? userType; 

  const RejectedScreen({super.key, this.userType});

  @override
  State<RejectedScreen> createState() => _RejectedScreenState();
}

class _RejectedScreenState extends State<RejectedScreen> {
  ApiService apiService = ApiService();
  bool isChangingRole = false;
  bool isChangingToClient = false;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    await ApiService.loadSession();
    setState(() {
      _userType = widget.userType ?? ApiService.userType?.toLowerCase();
    });
  }

  Future<void> changeToClient() async {
    setState(() {
      isChangingToClient = true;
    });

    try {
      final success = await apiService.updateUserType("client");

      if (success && mounted) {
        await ApiService.setUserType("client");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully switched to Client mode"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        debugPrint("Changed to client type");

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (_) => false,
          );
        }
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

  Future<void> switchToOtherRole() async {
    setState(() {
      isChangingRole = true;
    });

    try {
      final currentType = _userType;
      String newType;
      
      if (currentType == "shop") {
        newType = "carrier";
      } else if (currentType == "carrier") {
        newType = "shop";
      } else {
        newType = "client"; 
      }

      final success = await apiService.updateUserType(newType);

      if (success && mounted) {
        await ApiService.setUserType(newType);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully switched to ${newType.toUpperCase()} mode"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        debugPrint("Changed to $newType type");

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (_) => false,
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to switch to ${newType.toUpperCase()} mode"),
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
          isChangingRole = false;
        });
      }
    }
  }

  void _showContinueAsClientDialog() {
    final isShop = _userType == "shop";
    final title = isShop
        ? "Shop Application Rejected"
        : "Carrier Application Rejected";
    final message = isShop
        ? "Your shop application was rejected. Would you like to continue as a Client instead?"
        : "Your carrier application was rejected. Would you like to continue as a Client instead?";
    const infoMessage =
        "As a Client, you can book deliveries without going through verification.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isShop ? Icons.store : Icons.person, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 101, 100, 100),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.redAccent,
                      ),
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
              Navigator.pop(context);
              changeToClient();
            },
            child: const Text("Continue as Client"),
          ),
        ],
      ),
    );
  }

  void _showContinueAsOtherRoleDialog() {
    final isShop = _userType == "shop";
    final switchRole = isShop ? "Carrier" : "Shop";
    final title = isShop
        ? "Shop Application Rejected"
        : "Carrier Application Rejected";
    final message = isShop
        ? "Your shop application was rejected. Would you like to continue as a Carrier instead?"
        : "Your carrier application was rejected. Would you like to continue as a Shop instead?";
    final infoMessage = isShop
        ? "As a Carrier, you can deliver packages and earn money."
        : "As a Shop, you can send packages and manage deliveries.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isShop ? Icons.store : Icons.local_shipping, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 101, 100, 100),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.redAccent,
                      ),
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
              Navigator.pop(context);
              switchToOtherRole();
            },
            child: Text("Continue as $switchRole"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRetry() async {
    await ApiService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShop = _userType == "shop";
    final title = isShop ? "Shop\nRejected" : "Account\nRejected";
    final subtitle = isShop
        ? "We were unable to verify your shop information at this time. Please ensure your shop documents are clear and valid."
        : "We were unable to verify your information at this time. Please ensure your documents are clear and valid.";
    const alternativeTitle = "Alternative Options";
    final switchRoleText = isShop ? "Continue as Carrier" : "Continue as Shop";
    final switchDescription = isShop 
        ? "Switch to carrier mode and start delivering packages" 
        : "Switch to shop mode and start sending packages";
    const clientButtonText = "Continue as Client";
    const clientDescription = "Skip verification and use Qdel as a client";
    const retryButtonText = "Retry Registration";
    const footerText = "PLEASE TRY AGAIN";

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
                  children: [
                    Icon(
                      isShop ? Icons.store : Icons.error_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isShop ? "SHOP STATUS" : "ACCOUNT STATUS",
                      style: const TextStyle(
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
                child: Icon(
                  isShop ? Icons.store : Icons.close,
                  color: Colors.white,
                  size: 70,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                    Row(
                      children: [
                        Icon(
                          Icons.switch_account,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          alternativeTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: isChangingRole ? null : _showContinueAsOtherRoleDialog,
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
                          child: isChangingRole
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isShop ? Icons.local_shipping : Icons.store,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      switchRoleText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
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

                    Center(
                      child: Text(
                        switchDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: isChangingToClient ? null : _showContinueAsClientDialog,
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      clientButtonText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
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

                    Center(
                      child: Text(
                        clientDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: _handleRetry,
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
                      children: [
                        Icon(
                          isShop ? Icons.store : Icons.refresh,
                          color: ColorConstants.black,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          retryButtonText,
                          style: const TextStyle(
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

              Text(
                footerText,
                style: const TextStyle(
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