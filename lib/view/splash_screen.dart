import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/model/shop_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/dashboard_screen.dart';
import 'package:projectqdel/view/carrier/accepted_screen.dart';
import 'package:projectqdel/view/carrier/approved_screen.dart';
import 'package:projectqdel/view/carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/carrier/carrier_upload.dart';
import 'package:projectqdel/view/carrier/rejected_screen.dart';
import 'package:projectqdel/view/carrier/status_pending.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:projectqdel/view/login_screen.dart';
import 'package:projectqdel/view/shop/shop_home.dart';
import 'package:projectqdel/view/shop/shop_registration.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ApiService apiService = ApiService();
  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    splash();
  }

  Future<void> splash() async {
    await ApiService.loadSession();

    final token = ApiService.accessToken;
    if (token != null) {
      try {
        final refreshedUserType = await apiService.refreshUserType();
        if (refreshedUserType != null) {
          ApiService.userType = refreshedUserType;
        }
      } catch (e) {
        logger.e("Failed to refresh user type: $e");
      }
    }

    final userType = ApiService.userType?.toLowerCase();
    String? status = ApiService.approvalStatus?.toLowerCase();

    if (userType == "carrier") {
      status = await ApiService().checkApprovalStatus();

      if (status != null) {
        await ApiService.setApprovalStatus(status);
      }
    }

    debugPrint("TOKEN=$token | TYPE=$userType | STATUS=$status");

    if (token == null || userType == null) {
      go(const LoginScreen());
      return;
    }

    switch (userType) {
      case "admin":
        go(const DashboardScreen());
        break;

      case "client":
        go(const ClientDashboard());
        break;

      case "shop":
        await handleShopNavigation(); // Changed this line
        break;

      // case "carrier":
      //   await handleCarrierNavigation(); // Changed this line
      //   break;

      case "carrier":
        final profile = await apiService.getMyProfile();

        // Only check the document field from profile - NOT multiple sources
        final profileHasDocs = profile?.hasUploadedDocs ?? false;

        // Remove the API check - it might be returning false positive
        // bool apiHasDocs = false;
        // try {
        //   apiHasDocs = await apiService.checkDocumentStatus();
        // } catch (_) {}

        // Remove stored docs check - don't rely on cached value
        // final storedHasDocs = await ApiService.getHasUploadedDocs() ?? false;

        // Use ONLY profileHasDocs
        final hasDocs =
            profileHasDocs; // Changed: removed apiHasDocs and storedHasDocs

        String status = profile?.approvalStatus.trim().toLowerCase() ?? "";

        if (status.isEmpty) {
          final cachedStatus = ApiService.approvalStatus;
          if (cachedStatus != null && cachedStatus.trim().isNotEmpty) {
            status = cachedStatus.trim().toLowerCase();
          }
        }

        if (hasDocs && status.isEmpty) {
          try {
            final apiStatusRaw = await apiService.checkApprovalStatus();
            if (apiStatusRaw != null && apiStatusRaw.trim().isNotEmpty) {
              status = apiStatusRaw.trim().toLowerCase();
              await ApiService.setApprovalStatus(status);
            }
          } catch (_) {}
        }

        final activeOrderId = await ApiService.getActiveOrder();
        final cachedOrder = await ApiService.getActiveOrderDetails();

        if (cachedOrder != null && cachedOrder.id == activeOrderId) {
          go(AcceptedOrderScreen(orderId: activeOrderId!, order: cachedOrder));
          return;
        }

        if (!hasDocs) {
          go(
            CarrierUploadScreen(
              registrationData: CarrierRegistrationData(
                phone: profile!.phone,
                firstname: profile.firstName,
                lastname: profile.lastName,
                email: profile.email,
                userType: "carrier",
                countryId: profile.countryId,
                stateId: profile.stateId,
                districtId: profile.districtId,
                isExistingUser: true,
                parcelResponsibilityAccepted: true,
                damageLossAccepted: true,
                payoutTermsAccepted: true,
              ),
            ),
          );
          return;
        }

        if (status == "pending") {
          go(StatusPending(phone: profile!.phone));
          return;
        }

        if (status == "approved") {
          final hasSeen = await apiService.hasUserSeenApprovalScreen();

          if (!hasSeen) {
            go(const AccountApprovedScreen());
          } else {
            go(const CarrierDashboard());
          }
          return;
        }

        if (status == "rejected") {
          go(const RejectedScreen());
          return;
        }

        if (hasDocs) {
          go(StatusPending(phone: profile!.phone));
        } else {
          go(const CarrierDashboard());
        }
        break;
    }
  }

  void go(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/image_assets/logo_qdel.png",
          fit: BoxFit.cover,
          height: 220,
          width: 220,
        ),
      ),
    );
  }

  Future<void> handleShopNavigation() async {
    try {
      final profile = await apiService.getMyProfile();

      if (profile == null) {
        logger.e("❌ No shop profile found");
        go(LoginScreen());
        return;
      }

      final profileHasDocs = profile.hasShopDocuments;
      final hasDocs = profileHasDocs;

      String status = profile.shopApprovalStatus?.trim().toLowerCase() ?? "";

      if (status.isEmpty) {
        final cachedStatus = ApiService.approvalStatus;
        if (cachedStatus != null && cachedStatus.trim().isNotEmpty) {
          status = cachedStatus.trim().toLowerCase();
        }
      }

      if (hasDocs && status.isEmpty) {
        try {
          final apiStatusRaw = await apiService.checkApprovalStatus();
          if (apiStatusRaw != null && apiStatusRaw.trim().isNotEmpty) {
            status = apiStatusRaw.trim().toLowerCase();
            await ApiService.setApprovalStatus(status);
          }
        } catch (_) {}
      }

      final shopName = profile.shopName ?? "";

      logger.i(
        "🏪 SHOP DATA: Name=$shopName, Status=$status, HasDocs=$hasDocs",
      );

      if (shopName.isEmpty) {
        go(
          ShopRegistrationScreen(
            registrationData: ShopRegistrationData(
              phone: profile.phone,
              firstname: profile.firstName,
              lastname: profile.lastName,
              email: profile.email,
              userType: "shop",
              isExistingUser: true,
              countryId: profile.countryId,
              stateId: profile.stateId,
              districtId: profile.districtId,
              parcelResponsibilityAccepted:
                  profile.parcelResponsibilityAccepted,
              damageLossAccepted: profile.damageLossAccepted,
              payoutTermsAccepted: profile.payoutTermsAccepted,
            ),
          ),
        );
        return;
      }

      if (!hasDocs) {
        go(
          ShopRegistrationScreen(
            registrationData: ShopRegistrationData(
              phone: profile.phone,
              firstname: profile.firstName,
              lastname: profile.lastName,
              email: profile.email,
              userType: "shop",
              isExistingUser: true,
              countryId: profile.countryId,
              stateId: profile.stateId,
              districtId: profile.districtId,
              parcelResponsibilityAccepted:
                  profile.parcelResponsibilityAccepted,
              damageLossAccepted: profile.damageLossAccepted,
              payoutTermsAccepted: profile.payoutTermsAccepted,
            ),
          ),
        );
        return;
      }

      if (status == "pending") {
        go(StatusPending(phone: profile.phone));
        return;
      }

      if (status == "approved") {
        final hasSeen = await apiService.hasUserSeenApprovalScreen();

        if (!hasSeen) {
          go(AccountApprovedScreen());
        } else {
          go(const ShopHome());
        }
        return;
      }

      if (status == "rejected") {
        go(const RejectedScreen());
        return;
      }
      if (hasDocs) {
        go(const ShopHome());
      } else {
        go(StatusPending(phone: profile.phone));
      }
    } catch (e, stack) {
      logger.e("❌ Error in shop navigation: $e", stackTrace: stack);
      go(LoginScreen());
    }
  }

  Future<void> handleCarrierNavigation() async {
    try {
      final profile = await apiService.getMyProfile();

      final profileHasDocs = profile?.hasUploadedDocs ?? false;

      bool apiHasDocs = false;
      try {
        apiHasDocs = await apiService.checkDocumentStatus();
      } catch (_) {}

      final storedHasDocs = await ApiService.getHasUploadedDocs() ?? false;

      final hasDocs = profileHasDocs || apiHasDocs || storedHasDocs;

      String status = profile?.approvalStatus.trim().toLowerCase() ?? "";

      if (status.isEmpty) {
        final cachedStatus = ApiService.approvalStatus;
        if (cachedStatus != null && cachedStatus.trim().isNotEmpty) {
          status = cachedStatus.trim().toLowerCase();
        }
      }

      if (hasDocs && status.isEmpty) {
        try {
          final apiStatusRaw = await apiService.checkApprovalStatus();
          if (apiStatusRaw != null && apiStatusRaw.trim().isNotEmpty) {
            status = apiStatusRaw.trim().toLowerCase();
            await ApiService.setApprovalStatus(status);
          }
        } catch (_) {}
      }

      final activeOrderId = await ApiService.getActiveOrder();
      final cachedOrder = await ApiService.getActiveOrderDetails();

      if (cachedOrder != null && cachedOrder.id == activeOrderId) {
        go(AcceptedOrderScreen(orderId: activeOrderId!, order: cachedOrder));
        return;
      }

      if (!hasDocs) {
        go(
          CarrierUploadScreen(
            registrationData: CarrierRegistrationData(
              phone: profile!.phone,
              firstname: profile.firstName,
              lastname: profile.lastName,
              email: profile.email,
              userType: "carrier",
              countryId: profile.countryId,
              stateId: profile.stateId,
              districtId: profile.districtId,
              isExistingUser: true,
              parcelResponsibilityAccepted: true,
              damageLossAccepted: true,
              payoutTermsAccepted: true,
            ),
          ),
        );
        return;
      }

      if (status == "pending") {
        go(StatusPending(phone: profile!.phone));
        return;
      }

      if (status == "approved") {
        final hasSeen = await apiService.hasUserSeenApprovalScreen();

        if (!hasSeen) {
          go(const AccountApprovedScreen());
        } else {
          go(const CarrierDashboard());
        }
        return;
      }

      if (status == "rejected") {
        go(const RejectedScreen());
        return;
      }

      if (hasDocs) {
        go(StatusPending(phone: profile!.phone));
      } else {
        go(const CarrierDashboard());
      }
    } catch (e, stack) {
      logger.e("❌ Error in carrier navigation: $e", stackTrace: stack);
      go(LoginScreen());
    }
  }
}
