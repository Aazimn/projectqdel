import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:projectqdel/model/carrier_model.dart';
import 'package:projectqdel/model/shop_model.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/dashboard_screen.dart';
import 'package:projectqdel/view/Registration/login_screen.dart';
import 'package:projectqdel/view/carrier/accepted_screen.dart';
import 'package:projectqdel/view/carrier/approved_screen.dart';
import 'package:projectqdel/view/carrier/carrier_dashboard.dart';
import 'package:projectqdel/view/carrier/carrier_upload.dart';
import 'package:projectqdel/view/carrier/rejected_screen.dart';
import 'package:projectqdel/view/carrier/status_pending.dart';
import 'package:projectqdel/view/Client/client_dashboard.dart';
import 'package:projectqdel/view/Shop/shop_dashboard.dart';
import 'package:projectqdel/view/Shop/shop_registration.dart';

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
        await handleShopNavigation();
        break;

      case "carrier":
        final profile = await apiService.getMyProfile();

        if (profile == null) {
          logger.e("❌ No carrier profile found");
          go(LoginScreen());
          return;
        }

        final hasDocs = profile.hasUploadedDocs;

        final storedHasDocs = await ApiService.getHasUploadedDocs() ?? false;
        final finalHasDocs = hasDocs || storedHasDocs;
        String status = profile.approvalStatus.trim().toLowerCase();

        if (status.isEmpty) {
          final cachedStatus = ApiService.approvalStatus;
          if (cachedStatus != null && cachedStatus.trim().isNotEmpty) {
            status = cachedStatus.trim().toLowerCase();
          }
        }

        logger.i(
          "📊 Carrier - HasDocs: $finalHasDocs, HasCarrierDocument: ${profile.carrierDocument != null}, Status: $status",
        );

        if (status == "approved" && !finalHasDocs) {
          if (profile.carrierDocument != null &&
              profile.carrierDocument!.hasCarrierDocument) {
            logger.i("✅ Approved carrier has carrier_document - setting flag");
            await ApiService.setHasUploadedDocs(true);
            final finalDocsCheck =
                hasDocs || (await ApiService.getHasUploadedDocs() ?? false);
            if (finalDocsCheck) {}
          }
        }

        final finalDocs =
            hasDocs || (await ApiService.getHasUploadedDocs() ?? false);

        if (!finalDocs && status != "approved") {
          go(
            CarrierUploadScreen(
              registrationData: CarrierRegistrationData(
                phone: profile.phone,
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

        final activeOrderId = await ApiService.getActiveOrder();
        final cachedOrder = await ApiService.getActiveOrderDetails();
        final activeDropId =
            await ApiService.getActiveDropId(); // ← fetch drop ID first

        if (cachedOrder != null && cachedOrder.id == activeOrderId) {
          logger.i(
            "✅ Resuming order flow - OrderId: $activeOrderId, DropId: $activeDropId",
          );
          go(
            AcceptedOrderScreen(
              orderId: activeOrderId!,
              order: cachedOrder,
              selectedShopDropId:
                  activeDropId, // ← always pass it (null if not set)
            ),
          );
          return;
        }

        if (status == "pending") {
          go(StatusPending(phone: profile.phone, userType: "carrier"));
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
          go(const RejectedScreen(userType: "carrier"));
          return;
        }

        if (finalDocs) {
          go(StatusPending(phone: profile.phone, userType: "carrier"));
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
        go(StatusPending(phone: profile.phone, userType: "shop"));
        return;
      }

      if (status == "approved") {
        final hasSeen = await apiService.hasUserSeenApprovalScreen();

        if (!hasSeen) {
          go(AccountApprovedScreen());
        } else {
          go(const ShopDashboard());
        }
        return;
      }

      if (status == "rejected") {
        go(const RejectedScreen(userType: "shop"));
        return;
      }

      if (hasDocs) {
        go(const ShopDashboard());
      } else {
        go(StatusPending(phone: profile.phone, userType: "shop"));
      }
    } catch (e, stack) {
      logger.e("❌ Error in shop navigation: $e", stackTrace: stack);
      go(LoginScreen());
    }
  }
}
