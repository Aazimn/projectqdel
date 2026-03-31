import 'package:flutter/material.dart';
import 'dart:async';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Carrier/approved_screen.dart';
import 'package:projectqdel/view/Carrier/rejected_screen.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/view/CommonPages/splash_screen.dart';
import 'package:projectqdel/view/Registration/login_screen.dart';


class StatusPending extends StatefulWidget {
  final String phone;
  final String? userType;

  const StatusPending({super.key, required this.phone, this.userType});

  @override
  State<StatusPending> createState() => _StatusPendingState();
}

class _StatusPendingState extends State<StatusPending> {
  Timer? statusTimer;
  final api = ApiService();
  bool isChangingRole = false;
  bool isChangingToClient = false;
  String? currentUserType;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    startCheckingStatus();
  }

  Future<void> _loadUserType() async {
    await ApiService.loadSession();
    setState(() {
      currentUserType = widget.userType ?? ApiService.userType?.toLowerCase();
    });
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> changeToClient() async {
    setState(() {
      isChangingToClient = true;
    });

    try {
      final success = await api.updateUserType("client");

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
      final currentType = currentUserType;
      String newType;

      if (currentType == "shop") {
        newType = "carrier";
      } else if (currentType == "carrier") {
        newType = "shop";
      } else {
        newType = "client"; 
      }

      final success = await api.updateUserType(newType);

      if (success && mounted) {
        await ApiService.setUserType(newType);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Successfully switched to ${newType.toUpperCase()} mode",
            ),
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

  void startCheckingStatus() {
    statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await ApiService.loadSession();

      String? statusRaw;
      final isShop = currentUserType == "shop";

      if (isShop) {
        statusRaw = await api.checkShopApprovalStatus();
        if (statusRaw != null) {
          await ApiService.setApprovalStatus(statusRaw);
        }
      } else {
        statusRaw = await api.checkApprovalStatus();
        if (statusRaw != null) {
          await ApiService.setApprovalStatus(statusRaw);
        }
      }

      if (!mounted) return;
      if (statusRaw == null) return;
      final status = statusRaw.trim().toLowerCase();
      debugPrint("LIVE STATUS for ${isShop ? 'SHOP' : 'CARRIER'} => $status");

      if (status == "approved") {
        await ApiService.setApprovalStatus("approved");

        if (isShop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AccountApprovedScreen()),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AccountApprovedScreen()),
            (_) => false,
          );
        }
      } else if (status == "rejected") {
        await ApiService.setApprovalStatus("rejected");

        if (isShop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RejectedScreen()),
            (_) => false,
          );

          _showRejectedDialog(isShop: true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RejectedScreen()),
            (_) => false,
          );
        }
      }
    });
  }

  void _showRejectedDialog({required bool isShop}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Application Rejected"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your ${isShop ? 'shop' : 'carrier'} application has been rejected.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                "You can either switch to client mode or contact support for more information.",
                style: TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await changeToClient();
            },
            child: const Text("Switch to Client"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (_) => false,
              );
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  void _showContinueAsClientDialog() {
    final isShop = currentUserType == "shop";
    final title = isShop
        ? "Shop Application Pending"
        : "Carrier Application Pending";
    final message = isShop
        ? "Your shop application is pending verification. Would you like to continue as a Client instead?"
        : "Your carrier application is pending verification. Would you like to continue as a Client instead?";
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
    final isShop = currentUserType == "shop";
    final switchRole = isShop ? "Carrier" : "Shop";
    final title = isShop
        ? "Shop Application Pending"
        : "Carrier Application Pending";
    final message = isShop
        ? "Your shop application is pending verification. Would you like to continue as a Carrier instead?"
        : "Your carrier application is pending verification. Would you like to continue as a Shop instead?";
    final infoMessage = isShop
        ? "As a Carrier, you can deliver packages and earn money."
        : "As a Shop, you will get packages and manage deliveries.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isShop ? Icons.store : Icons.local_shipping,
              color: Colors.redAccent,
            ),
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

  @override
  Widget build(BuildContext context) {
    final isShop = currentUserType == "shop";
    final title = isShop
        ? "SHOP APPLICATION STATUS"
        : "CARRIER APPLICATION STATUS";
    const subtitle = "Verification in\nProgress";
    const badgeText = "Reviewing Documents";
    const description =
        "Your documents have been submitted. Our team is currently reviewing your profile. You will be notified once you are approved.";
    const alternativeTitle = "Alternative Options";
    final switchRoleText = isShop ? "Continue as Carrier" : "Continue as Shop";
    final switchDescription = isShop
        ? "Switch to carrier mode and start delivering packages"
        : "Switch to shop mode and start sending packages";
    const clientDescription = "Skip verification and use Qdel as a client";

    return Scaffold(
      backgroundColor: ColorConstants.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ColorConstants.black,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20),
                ],
              ),
              child: Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.08),
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: Icon(
                    isShop ? Icons.store : Icons.hourglass_empty,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorConstants.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.red.withOpacity(0.15),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                    onTap: isChangingRole
                        ? null
                        : _showContinueAsOtherRoleDialog,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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

                  Center(
                    child: Text(
                      clientDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColorConstants.black,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, color: ColorConstants.black),
                    SizedBox(width: 10),
                    Text(
                      "Contact Support",
                      style: TextStyle(
                        color: ColorConstants.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Estimated response time: 24-48 hours",
              style: TextStyle(color: ColorConstants.black, fontSize: 12),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
