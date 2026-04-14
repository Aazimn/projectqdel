import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/model/carrier_orders.dart';
import 'package:projectqdel/model/complaint_model.dart';
import 'package:projectqdel/model/drop_location.dart';
import 'package:projectqdel/model/order_model.dart';
import 'package:projectqdel/model/shop_workingdays.dart';
import 'package:projectqdel/model/delivery_model.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  int? lastCreatedProductId;
  int? currentUserId;
  final String baseurl =
      "https://girls-ppc-sides-series.trycloudflare.com";
  Logger logger = Logger();

  static bool? isFirstTime;
  static Future<void> setFirstTime(bool value) async {
    isFirstTime = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', value);
  }

  static String? approvalStatus;

  static Future<void> setApprovalStatus(String status) async {
    approvalStatus = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('approval_status', status);
  }

  static bool sessionLoaded = false;
  static String? accessToken;

  static Future<void> setToken(String token) async {
    accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
  }

  static bool? hasUploadedDocs;
  static const String _hasUploadedDocsKey = 'has_uploaded_docs';

  static Future<void> setHasUploadedDocs(bool value) async {
    hasUploadedDocs = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasUploadedDocsKey, value);
  }

  static Future<bool?> getHasUploadedDocs() async {
    if (hasUploadedDocs != null) return hasUploadedDocs;
    final prefs = await SharedPreferences.getInstance();
    hasUploadedDocs = prefs.getBool(_hasUploadedDocsKey);
    return hasUploadedDocs;
  }

  static Future<void> loadSession() async {
    if (sessionLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
    userType = prefs.getString('user_type');
    approvalStatus = prefs.getString('approval_status');
    phone = prefs.getString('phone');
    isFirstTime = prefs.getBool('first_time');
    hasUploadedDocs = prefs.getBool(_hasUploadedDocsKey);
    _hasSeenApprovalScreen = prefs.getBool('has_seen_approval');

    sessionLoaded = true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
    await prefs.remove('user_type');
    await prefs.remove('approval_status');
    await prefs.remove('phone');
    await prefs.remove('first_time');
    await prefs.remove(_hasUploadedDocsKey);
    await prefs.remove('has_seen_approval');

    await prefs.remove('user_id');
    await prefs.remove('country');
    await prefs.remove('state');
    await prefs.remove('district');

    await prefs.remove('pickup_carrier_id');
    await prefs.remove('active_order_id');
    await prefs.remove('active_order_details');

    await prefs.remove('shop_approval_status');
    await prefs.remove('has_registered_shop');

    final keys = prefs.getKeys();
    final keysToRemove = <String>[];
    for (final k in keys) {
      final isPerOrderCarrierId =
          k.startsWith('order_') && k.endsWith('_carrier_id');
      final isOrderStatusFlag =
          k.startsWith('arrived_') ||
          k.startsWith('otp_sent_') ||
          k.startsWith('verified_') ||
          k.startsWith('delivery_arrived_') ||
          k.startsWith('delivery_otp_sent_') ||
          k.startsWith('delivery_verified_');
      if (isPerOrderCarrierId || isOrderStatusFlag) {
        keysToRemove.add(k);
      }
    }
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }

    accessToken = null;
    userType = null;
    approvalStatus = null;
    phone = null;
    isFirstTime = null;
    hasUploadedDocs = null;
    _hasSeenApprovalScreen = null;
    sessionLoaded = false;
  }

  static String? userType;

  static Future<void> setUserType(String type) async {
    userType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type);
  }

  static Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
    userType = prefs.getString('user_type');
  }

  Future<bool> login({required String phone}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/request/otp/");
    var headers = {"Content-Type": "application/json"};
    var body = jsonEncode({"phone": phone});
    logger.i("URL :: $url");
    logger.i("HEADERS :: $headers");
    logger.i("BODY :: $body");

    try {
      final response = await http.post(url, headers: headers, body: body);

      logger.i("STATUS CODE :: ${response.statusCode}");
      logger.i("RESPONSE BODY :: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      logger.e("ERROR :: $e");
      return false;
    }
  }

  static String? phone;

  static Future<void> setPhone(String value) async {
    phone = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', value);
  }

  Future<Map<String, dynamic>?> otp({
    required String phone,
    required String otp,
  }) async {
    Uri url = Uri.parse("$baseurl/api/qdel/verify/otp/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "otp": otp}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      await ApiService.setToken(data['access']);
      final user = data['user'] ?? {};

      await ApiService.setPhone(user['phone'] ?? phone);
      currentUserId = user['id'];
      await ApiService.setUserId(user['id']);

      return data;
    }
    return null;
  }

  Future<dynamic> getCountries({int? page, String? search}) async {
    String urlString = "$baseurl/api/qdel/countries/add/";
    List<String> queryParams = [];

    if (page != null) {
      queryParams.add("page=$page");
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add("search=$search");
    }
    if (queryParams.isNotEmpty) {
      urlString += "?" + queryParams.join("&");
    }
    final url = Uri.parse(urlString);
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );
    logger.i("COUNTRIES STATUS :: ${response.statusCode}");
    logger.i("COUNTRIES BODY :: ${response.body}");
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map) {
        return data;
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception("Failed to load countries");
    }
  }

  Future<dynamic> getStatesByCountry({
    required int countryId,
    int? page,
    String? search,
  }) async {
    String urlString = "$baseurl/api/qdel/states/by/country/$countryId/";
    final queryParams = <String>[];
    if (page != null) queryParams.add("page=$page");
    if (search != null && search.isNotEmpty) {
      queryParams.add("search=$search");
    }
    if (queryParams.isNotEmpty) {
      urlString += "?${queryParams.join("&")}";
    }

    final url = Uri.parse(urlString);
    logger.i("🌐 STATES BY COUNTRY URL :: $url");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    logger.i("📊 STATES BY COUNTRY STATUS :: ${response.statusCode}");
    logger.i("📦 STATES BY COUNTRY BODY :: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded;
    } else {
      throw Exception("Failed to load states: ${response.statusCode}");
    }
  }

  Future<dynamic> getDistrictsByState({
    required int stateId,
    int? page,
    String? search,
  }) async {
    String urlString = "$baseurl/api/qdel/districts/by/state/$stateId/";
    final queryParams = <String>[];
    if (page != null) queryParams.add("page=$page");
    if (search != null && search.isNotEmpty) {
      queryParams.add("search=$search");
    }
    if (queryParams.isNotEmpty) {
      urlString += "?${queryParams.join("&")}";
    }

    final url = Uri.parse(urlString);
    logger.i("🌐 DISTRICTS BY STATE URL :: $url");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    logger.i("📊 DISTRICTS BY STATE STATUS :: ${response.statusCode}");
    logger.i("📦 DISTRICTS BY STATE BODY :: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded;
    } else {
      throw Exception("Failed to load districts: ${response.statusCode}");
    }
  }

  Future<bool> registration({
    required String phone,
    required String firstname,
    required String lastname,
    required String email,
    required String userType,
    required int? countryId,
    required int? stateId,
    required int? districtId,
    required bool parcelResponsibilityAccepted,
    required bool damageLossAccepted,
    required bool payoutTermsAccepted,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/register/");
    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({
      "Authorization": "Bearer ${ApiService.accessToken}",
    });

    request.fields.addAll({
      "phone": phone,
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "user_type": userType,
      if (countryId != null) "country": countryId.toString(),
      if (stateId != null) "state": stateId.toString(),
      if (districtId != null) "district": districtId.toString(),
      "parcel_responsibility_accepted": parcelResponsibilityAccepted.toString(),
      "damage_loss_accepted": damageLossAccepted.toString(),
      "payout_terms_accepted": payoutTermsAccepted.toString(),
    });

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      await ApiService.setFirstTime(false);
      return true;
    }
    return false;
  }

  Future<bool> shopRegistration({
    required String phone,
    required String firstname,
    required String lastname,
    required String email,
    required String userType,
    required int? countryId,
    required int? stateId,
    required int? districtId,
    required bool parcelResponsibilityAccepted,
    required bool damageLossAccepted,
    required bool payoutTermsAccepted,
    required String shopName,
    required int? shopCategory,
    required String address,
    required String landmark,
    required String zipCode,
    required double? latitude,
    required double? longitude,
    required int? shopcountryId,
    required int? shopstateId,
    required int? shopdistrictId,
    File? shopPhoto,
    File? shopDocument,
    File? ownerShopPhoto,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/register/");
    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({
      "Authorization": "Bearer ${ApiService.accessToken}",
    });

    request.fields.addAll({
      "phone": phone,
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "user_type": userType,
      if (countryId != null) "country": countryId.toString(),
      if (stateId != null) "state": stateId.toString(),
      if (districtId != null) "district": districtId.toString(),
      "parcel_responsibility_accepted": parcelResponsibilityAccepted.toString(),
      "damage_loss_accepted": damageLossAccepted.toString(),
      "payout_terms_accepted": payoutTermsAccepted.toString(),
      "shop_name": shopName,
      "shop_categories": shopCategory.toString(),
    });

    request.fields.addAll({
      "address": address,
      "landmark": landmark,
      "zip_code": zipCode,
      "latitude": latitude?.toString() ?? "",
      "longitude": longitude?.toString() ?? "",
      "district": shopdistrictId.toString(),
      "state": shopstateId.toString(),
      "country": shopcountryId.toString(),
    });

    if (shopPhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath("shop_photo", shopPhoto.path),
      );
    }

    if (shopDocument != null) {
      request.files.add(
        await http.MultipartFile.fromPath("shop_document", shopDocument.path),
      );
    }

    if (ownerShopPhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "owner_shop_photo",
          ownerShopPhoto.path,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      await ApiService.setFirstTime(false);
      return true;
    }

    return false;
  }

  Future<bool> carrierRegistrationWithDocument({
    required String phone,
    required String firstname,
    required String lastname,
    required String email,
    required bool parcelResponsibilityAccepted,
    required bool damageLossAccepted,
    required bool payoutTermsAccepted,
    required int? countryId,
    required int? stateId,
    required int? districtId,
    required File document,
    required File carrierphoto,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/register/");
    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({
      "Authorization": "Bearer ${ApiService.accessToken}",
    });

    request.fields.addAll({
      "phone": phone,
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "parcel_responsibility_accepted": parcelResponsibilityAccepted.toString(),
      "damage_loss_accepted": damageLossAccepted.toString(),
      "payout_terms_accepted": payoutTermsAccepted.toString(),
      "user_type": "carrier",
      if (countryId != null) "country": countryId.toString(),
      if (stateId != null) "state": stateId.toString(),
      if (districtId != null) "district": districtId.toString(),
    });

    request.files.add(
      await http.MultipartFile.fromPath("document", document.path),
    );

    request.files.add(
      await http.MultipartFile.fromPath("carrier_photo", carrierphoto.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    logger.i("CARRIER REGISTER STATUS :: ${response.statusCode}");
    logger.i("CARRIER REGISTER BODY :: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      await ApiService.setFirstTime(false);
      await ApiService.setHasUploadedDocs(true);
      return true;
    }
    return false;
  }

  Future<String?> refreshUserType() async {
    try {
      final response = await http.get(
        Uri.parse("$baseurl/api/qdel/users/detail/update/self/"),
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("REFRESH USER TYPE STATUS :: ${response.statusCode}");
      logger.i("REFRESH USER TYPE BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final newUserType = userData['user_type']?.toLowerCase();

        if (newUserType != null && newUserType != ApiService.userType) {
          await ApiService.setUserType(newUserType);
          logger.i(
            "✅ User type updated from ${ApiService.userType} to $newUserType",
          );
          return newUserType;
        }
        return ApiService.userType;
      }
      return ApiService.userType;
    } catch (e) {
      logger.e("REFRESH USER TYPE ERROR => $e");
      return ApiService.userType;
    }
  }

  Future<UserModel?> getMyProfile() async {
    final url = Uri.parse("$baseurl/api/qdel/users/detail/update/self/");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
    );

    logger.i("SELF PROFILE STATUS :: ${response.statusCode}");
    logger.i("SELF PROFILE BODY :: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['carrier_document'] != null) {
        logger.i(
          "📄 CARRIER DOCUMENT: ${data['carrier_document']['document']}",
        );
        logger.i("📸 SHOP PHOTO: ${data['carrier_document']['shop_photo']}");
        logger.i(
          "📄 SHOP DOCUMENT: ${data['carrier_document']['shop_document']}",
        );
        logger.i(
          "👤 OWNER PHOTO: ${data['carrier_document']['owner_shop_photo']}",
        );
      } else {
        logger.i("📄 CARRIER DOCUMENT: null");
      }
      logger.i("📄 LEGACY DOCUMENT FIELD: ${data['document']}");

      return UserModel.fromJson(data);
    }
    return null;
  }

  Future<bool> updateMyProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/users/detail/update/self/");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
      }),
    );

    logger.i("UPDATE PROFILE STATUS :: ${response.statusCode}");
    logger.i("UPDATE PROFILE BODY :: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<Map<String, dynamic>> getUsersByStatus({
    required String status,
    String? searchQuery,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      String urlString = "$baseurl/api/qdel/admin/users/$status/";

      final queryParams = <String, String>{};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();
      final uri = Uri.parse(urlString).replace(queryParameters: queryParams);

      logger.i("GET Users URL :: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        List<UserModel> users = [];
        if (jsonResponse['data'] != null) {
          users = (jsonResponse['data'] as List)
              .map((json) => UserModel.fromJson(json))
              .toList();
        }

        int totalCount = jsonResponse['count'] ?? users.length;
        int totalPages = (totalCount / pageSize).ceil();

        return {
          'users': users,
          'hasNext': (page * pageSize) < totalCount,
          'hasPrevious': page > 1,
          'totalPages': totalPages > 0 ? totalPages : 1,
          'currentPage': page,
          'count': totalCount,
        };
      } else {
        logger.e("Failed to fetch users: ${response.statusCode}");
        return {
          'users': [],
          'hasNext': false,
          'hasPrevious': false,
          'totalPages': 1,
          'currentPage': page,
          'count': 0,
        };
      }
    } catch (e) {
      logger.e("Error fetching users: $e");
      return {
        'users': [],
        'hasNext': false,
        'hasPrevious': false,
        'totalPages': 1,
        'currentPage': page,
        'count': 0,
      };
    }
  }

  Future<bool> updateUserStatus({
    required int userId,
    required String status,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/users/approval-status/update/$userId/",
      );

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"approval_status": status}),
      );
      logger.i("PATCH URL :: $url");
      logger.i("STATUS :: ${response.statusCode}");
      logger.i("BODY :: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      logger.e("Error updating user status: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getShopsByStatus({
    required String status,
    String? searchQuery,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      String urlString = "$baseurl/api/qdel/admin/shop/approval/$status/";

      final queryParams = <String, String>{};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      queryParams['page'] = page.toString();
      queryParams['page_size'] = pageSize.toString();

      final uri = Uri.parse(urlString).replace(queryParameters: queryParams);

      logger.i("GET Shops URL :: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        List shops = [];

        if (jsonResponse['data'] != null) {
          shops = jsonResponse['data'];
        }

        int totalCount = jsonResponse['count'] ?? shops.length;
        int totalPages = (totalCount / pageSize).ceil();

        return {
          'shops': shops,
          'hasNext': (page * pageSize) < totalCount,
          'hasPrevious': page > 1,
          'totalPages': totalPages > 0 ? totalPages : 1,
          'currentPage': page,
          'count': totalCount,
        };
      } else {
        logger.e("Failed to fetch shops: ${response.statusCode}");

        return {
          'shops': [],
          'hasNext': false,
          'hasPrevious': false,
          'totalPages': 1,
          'currentPage': page,
          'count': 0,
        };
      }
    } catch (e) {
      logger.e("Error fetching shops: $e");

      return {
        'shops': [],
        'hasNext': false,
        'hasPrevious': false,
        'totalPages': 1,
        'currentPage': page,
        'count': 0,
      };
    }
  }

  Future<bool> updateShopStatus({
    required int shopId,
    required String status,
  }) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/admin/shop/approval/$shopId/");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"shop_approval_status": status}),
      );

      logger.i("PATCH SHOP URL :: $url");
      logger.i("STATUS :: ${response.statusCode}");
      logger.i("BODY :: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      logger.e("Error updating shop status: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getShopDetailsByUserId(int userId) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/admin/shop/detail/$userId/");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      logger.i("SHOP DETAILS URL :: $url");
      logger.i("STATUS :: ${response.statusCode}");
      logger.i("BODY :: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }

      return null;
    } catch (e) {
      logger.e("Error fetching shop details: $e");
      return null;
    }
  }

  Future<bool> updateUserType(String userType) async {
    final url = Uri.parse("$baseurl/api/qdel/users/detail/update/self/");

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"user_type": userType}),
    );

    logger.i("USER TYPE UPDATE :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    return response.statusCode == 200 || response.statusCode == 204;
  }

  static Future<void> markRegistrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    isFirstTime = false;
  }

  Future<bool> carrierApproval({
    required int userId,
    required bool approve,
  }) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/admin/carrier-approval/status/$userId/",
    );
    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ApiService.accessToken}",
      },
      body: jsonEncode({"approval_status": approve ? "approved" : "rejected"}),
    );
    logger.i("PATCH URL :: $url");
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<void> saveSession({
    required String token,
    required String userType,
    required String approvalStatus,
    required String phone,
    required bool firstTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('accessToken', token);
    await prefs.setString('user_type', userType);
    await prefs.setString('approval_status', approvalStatus);
    await prefs.setString('phone', phone);
    await prefs.setBool('first_time', firstTime);
    ApiService.accessToken = token;
    ApiService.userType = userType;
    ApiService.approvalStatus = approvalStatus;
    ApiService.phone = phone;
    ApiService.isFirstTime = firstTime;
  }

  Future<String?> checkApprovalStatus() async {
    try {
      final response = await http.get(
        Uri.parse("$baseurl/api/qdel/register/"),
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("STATUS CHECK :: ${response.statusCode}");
      logger.i("STATUS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List users = decoded["data"];
        final myPhone = ApiService.phone;
        final myUser = users.firstWhere(
          (u) => u["phone"] == myPhone,
          orElse: () => null,
        );

        if (myUser == null) return null;

        return myUser["approval_status"];
      }
      return null;
    } catch (e) {
      logger.e("STATUS ERROR => $e");
      return null;
    }
  }

  Future<Map?> getRegistrationDetails() async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/register/");
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      logger.i("🌐 GET REGISTRATION URL :: $url");
      logger.i("📊 GET REGISTRATION STATUS :: ${response.statusCode}");
      logger.i("📦 GET REGISTRATION BODY :: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        } else if (data is Map) {
          return data;
        }
      }
      return null;
    } catch (e) {
      logger.e("❌ Error fetching registration details: $e");
      return null;
    }
  }

  Future<Map?> getShopStatus() async {
    return await getRegistrationDetails();
  }

  Future<List<dynamic>> countriesList() async {
    Uri url = Uri.parse("$baseurl/api/qdel/countries/add/");

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    logger.i("TOKEN :: ${ApiService.accessToken}");
    final response = await http.get(url, headers: headers);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token missing or expired");
    } else {
      throw Exception("Failed to load countries");
    }
  }

  Future<bool> addCountry({required String name, required String code}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/countries/add/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name, "code": code});
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.post(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("RESPONSE BODY :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token missing or expired");
    } else {
      throw Exception("Failed to add country");
    }
  }

  Future<bool> updateCountry({
    required int countryId,
    required String name,
    required String code,
  }) async {
    Uri url = Uri.parse("$baseurl/api/qdel/countries/update/$countryId/");

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };

    var body = jsonEncode({"name": name, "code": code});
    logger.i("UPDATE COUNTRY URL :: $url");
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.put(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? "Failed to update country");
      } catch (_) {
        throw Exception("Failed to update country");
      }
    }
  }

  Future<bool> deleteCountry({required int countryId}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/countries/update/$countryId/");

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized");
    } else {
      throw Exception("Failed to delete country");
    }
  }

  Future<bool> addstates({required String name, required int country}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/states/add/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name, "country": country});
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.post(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("RESPONSE BODY :: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token missing or expired");
    } else {
      throw Exception("Failed to add State");
    }
  }

  Future<bool> updateState({
    required int stateId,
    required String name,
    required int countryId,
  }) async {
    Uri url = Uri.parse("$baseurl/api/qdel/states/update/$stateId/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name, "country": countryId});
    logger.i("UPDATE STATE URL :: $url");
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.put(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? "Failed to update state");
      } catch (_) {
        throw Exception("Failed to update state");
      }
    }
  }

  Future<bool> deleteState({required int stateId}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/states/update/$stateId/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    logger.i("DELETE STATE URL :: $url");
    logger.i("TOKEN :: ${ApiService.accessToken}");
    final response = await http.delete(url, headers: headers);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? "Failed to delete state");
      } catch (_) {
        throw Exception("Failed to delete state");
      }
    }
  }

  Future<bool> addDistrict({required String name, required int stateId}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/districts/add/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name, "state": stateId});
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.post(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("RESPONSE BODY :: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token missing or expired");
    } else {
      throw Exception("Failed to add District");
    }
  }

  Future<bool> updateDistrict({
    required int districtId,
    required String name,
    required int stateId,
  }) async {
    Uri url = Uri.parse("$baseurl/api/qdel/districts/update/$districtId/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name, "state": stateId});
    logger.i("UPDATE DISTRICT URL :: $url");
    logger.i("TOKEN :: ${ApiService.accessToken}");
    logger.i("BODY SENT :: $body");
    final response = await http.put(url, headers: headers, body: body);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? "Failed to update district");
      } catch (_) {
        throw Exception("Failed to update district");
      }
    }
  }

  Future<bool> deleteDistrict({required int districtId}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/districts/update/$districtId/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    logger.i("DELETE DISTRICT URL :: $url");
    logger.i("TOKEN :: ${ApiService.accessToken}");
    final response = await http.delete(url, headers: headers);
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized - Token expired");
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? "Failed to delete district");
      } catch (_) {
        throw Exception("Failed to delete district");
      }
    }
  }

  static bool? _hasSeenApprovalScreen;

  Future<bool> markApprovalScreenSeen() async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/user/click/update/");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("MARK APPROVAL SEEN STATUS :: ${response.statusCode}");
      logger.i("MARK APPROVAL SEEN BODY :: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ApiService.setApprovalScreenSeen(true);
        return true;
      }
      return false;
    } catch (e) {
      logger.e("MARK APPROVAL SEEN ERROR => $e");
      return false;
    }
  }

  Future<bool> hasUserSeenApprovalScreen() async {
    try {
      if (_hasSeenApprovalScreen != null) {
        return _hasSeenApprovalScreen!;
      }

      final url = Uri.parse("$baseurl/api/qdel/user/click/update/");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("CHECK APPROVAL SEEN STATUS :: ${response.statusCode}");
      logger.i("CHECK APPROVAL SEEN BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hasSeen = data['is_clicked'] ?? false;

        await ApiService.setApprovalScreenSeen(hasSeen);
        return hasSeen;
      }

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool('has_seen_approval');
      if (cached != null) {
        _hasSeenApprovalScreen = cached;
        return cached;
      }

      return false;
    } catch (e) {
      logger.e("CHECK APPROVAL SEEN ERROR => $e");

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool('has_seen_approval');
      if (cached != null) {
        _hasSeenApprovalScreen = cached;
        return cached;
      }
      return false;
    }
  }

  static Future<void> setApprovalScreenSeen(bool value) async {
    _hasSeenApprovalScreen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_approval', value);
  }

  static Future<bool?> getApprovalScreenSeen() async {
    if (_hasSeenApprovalScreen != null) return _hasSeenApprovalScreen;

    final prefs = await SharedPreferences.getInstance();
    _hasSeenApprovalScreen = prefs.getBool('has_seen_approval');
    return _hasSeenApprovalScreen;
  }

  Future<bool> uploadCarrierDocument({
    required File document,
    required int? countryId,
    required int? stateId,
    required int? districtId,
  }) async {
    final logger = Logger();

    final url = Uri.parse("$baseurl/api/qdel/users/carrier/document/upload/");

    try {
      logger.i("══════════════════════════════════════");
      logger.i("🚀 START CARRIER DOCUMENT UPLOAD");
      logger.i("══════════════════════════════════════");

      logger.i("🌐 API URL → $url");

      logger.i("📂 FILE DETAILS");
      logger.i("📄 PATH → ${document.path}");
      logger.i("📦 SIZE → ${await document.length()} bytes");

      logger.i("📍 LOCATION DATA");
      logger.i("🌍 COUNTRY → $countryId");
      logger.i("🏙 STATE → $stateId");
      logger.i("📌 DISTRICT → $districtId");

      var request = http.MultipartRequest("POST", url);

      request.headers.addAll({"Authorization": "Bearer $accessToken"});

      logger.i("📨 REQUEST HEADERS → ${request.headers}");

      if (countryId != null) request.fields["country"] = countryId.toString();
      if (stateId != null) request.fields["state"] = stateId.toString();
      if (districtId != null)
        request.fields["district"] = districtId.toString();

      logger.i("📨 REQUEST FIELDS → ${request.fields}");

      logger.i("📤 Preparing multipart file");

      var multipartFile = await http.MultipartFile.fromPath(
        "document",
        document.path,
      );

      request.files.add(multipartFile);

      logger.i("📎 FILE ATTACHED");
      logger.i("📄 FIELD NAME → document");
      logger.i("📄 FILE NAME → ${multipartFile.filename}");
      logger.i("📦 FILE LENGTH → ${multipartFile.length}");

      logger.i("📤 Sending multipart request...");

      var streamedResponse = await request.send();

      logger.i("📡 RESPONSE RECEIVED");

      var responseBody = await streamedResponse.stream.bytesToString();

      logger.i("📡 STATUS CODE → ${streamedResponse.statusCode}");
      logger.i("📡 RESPONSE BODY → $responseBody");

      logger.i("══════════════════════════════════════");

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        logger.i("✅ DOCUMENT UPLOAD SUCCESS");
        await ApiService.setHasUploadedDocs(true);
        return true;
      }

      logger.e("❌ DOCUMENT UPLOAD FAILED");
      return false;
    } catch (e, stack) {
      logger.e("❌ DOCUMENT UPLOAD EXCEPTION");
      logger.e("ERROR → $e");
      logger.e("STACK → $stack");
      return false;
    }
  }

  Future<bool> addProduct({
    required String name,
    required String description,
    required String volume,
    required String actualWeight,
    File? image,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseurl/api/qdel/users/products/add/"),
    );
    request.headers.addAll({
      "Authorization": "Bearer ${ApiService.accessToken}",
    });
    request.fields.addAll({
      "name": name,
      "description": description,
      "volume": volume,
      "actual_weight": actualWeight,
    });
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath("image", image.path));
    }
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    logger.i("PRODUCT STATUS :: ${response.statusCode}");
    logger.i("PRODUCT BODY :: $responseBody");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(responseBody);
      lastCreatedProductId = decoded["product_id"];
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getProductById(int productId) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/users/products/detail/view/update/$productId/",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
    );

    logger.i("GET PRODUCT STATUS :: ${response.statusCode}");
    logger.i("GET PRODUCT BODY :: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> updateProduct({
    required int productId,
    required String name,
    required String description,
    required String actualWeight,
    required String volume,
    File? productImage,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/users/products/detail/view/update/$productId/",
      );

      var request = http.MultipartRequest('PUT', url);

      request.headers.addAll({
        "Authorization": "Bearer ${ApiService.accessToken}",
      });

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['actual_weight'] = actualWeight;
      request.fields['volume'] = volume;

      if (productImage != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'image',
          productImage.path,
        );
        request.files.add(multipartFile);
        logger.i("📸 Image added to request: ${productImage.path}");
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      logger.i("UPDATE PRODUCT STATUS :: ${streamedResponse.statusCode}");
      logger.i("UPDATE PRODUCT BODY :: $responseBody");

      return streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 202;
    } catch (e, stackTrace) {
      logger.e("Error updating product: $e", stackTrace: stackTrace);
      return false;
    }
  }

  Future<List<dynamic>> getProducts() async {
    final uri = Uri.parse("$baseurl/api/qdel/users/products/");

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("GET PRODUCTS STATUS :: ${response.statusCode}");
      logger.i("GET PRODUCTS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        return decoded["data"] ?? decoded;
      }
    } catch (e) {
      logger.e("GET PRODUCTS ERROR :: $e");
    }

    return [];
  }

  Future<int?> addSenderAddress({
    required String name,
    required String phone,
    required String address,
    required String landmark,
    required int? district,
    required int? state,
    required int? country,
    required String zipCode,
    required String? latitude,
    required String? longitude,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/users/addresses/");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "sender_name": name,
        "address": address,
        "phone_number": phone,
        "landmark": landmark,
        "district": district,
        "state": state,
        "country": country,
        "zip_code": zipCode,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    logger.i("ADD ADDRESS STATUS => ${response.statusCode}");
    logger.i("ADD ADDRESS BODY => ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);

        final data = decoded["data"];

        if (data != null && data["id"] != null) {
          return data["id"] as int;
        }

        logger.w("⚠️ Address saved but ID not returned, fetching latest...");

        final addresses = await getSenderAddresses();
        if (addresses.isNotEmpty) {
          final latestId = addresses.first['id'] as int;
          logger.i("✅ Using latest address ID: $latestId");
          return latestId;
        }
        logger.e("❌ Could not retrieve address ID even after fetching");
        return null;
      } catch (e) {
        logger.e("❌ JSON parse error: $e");
        return null;
      }
    }

    logger.e("❌ Failed to add sender address");
    return null;
  }

  Future<int?> addReceiverAddress({
    required String receiverName,
    required String receiverPhone,
    required String address,
    required String landmark,
    required int? district,
    required int? state,
    required int? country,
    required String zipCode,
    required String? latitude,
    required String? longitude,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/receiver/address/");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "receiver_name": receiverName,
        "receiver_phone": receiverPhone,
        "address_text": address,
        "landmark": landmark,
        "district": district,
        "state": state,
        "country": country,
        "zip_code": zipCode,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    logger.i("ADD RECEIVER ADDRESS STATUS => ${response.statusCode}");
    logger.i("ADD RECEIVER ADDRESS BODY => ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded["id"] != null) {
          return decoded["id"] as int;
        } else if (decoded["data"] != null && decoded["data"]["id"] != null) {
          return decoded["data"]["id"] as int;
        } else if (decoded["address_id"] != null) {
          return decoded["address_id"] as int;
        }

        logger.w(
          "⚠️ Receiver address saved but ID not returned, fetching latest...",
        );

        final addresses = await getReceiverAddresses();
        if (addresses.isNotEmpty) {
          final latestId = addresses.first['id'] as int;
          logger.i("✅ Using latest receiver address ID: $latestId");
          return latestId;
        }

        return null;
      } catch (e) {
        logger.e("❌ JSON parse error: $e");
        return null;
      }
    }

    logger.e("❌ Failed to add receiver address");
    return null;
  }

  Future<List<dynamic>> getReceiverAddresses() async {
    final url = Uri.parse("$baseurl/api/qdel/receiver/address/");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      },
    );

    logger.i("GET RECEIVER ADDRESSES STATUS => ${response.statusCode}");
    logger.i("GET RECEIVER ADDRESSES BODY => ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"] as List<dynamic>;
    }

    return [];
  }

  static Future<void> setUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
  }

  Future<Map<String, dynamic>?> getSenderAddressById(int addressId) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/users/addresses/update/$addressId/",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("GET ADDRESS STATUS => ${response.statusCode}");
      logger.i("GET ADDRESS BODY => ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      logger.e("GET ADDRESS ERROR => $e");
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getSenderAddresses() async {
    final url = Uri.parse("$baseurl/api/qdel/users/addresses/");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("GET SENDER ADDRESSES STATUS => ${response.statusCode}");
      logger.i("GET SENDER ADDRESSES BODY => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        }
        if (decoded is Map && decoded["results"] is List) {
          return List<Map<String, dynamic>>.from(decoded["results"]);
        }
      }
    } catch (e) {
      logger.e("GET SENDER ADDRESSES ERROR => $e");
    }

    return [];
  }

  Future<bool> deleteSenderAddress({required int addressId}) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/users/addresses/update/$addressId/",
    );

    try {
      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("DELETE SENDER STATUS => ${response.statusCode}");
      logger.i("DELETE SENDER BODY => ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e("DELETE SENDER ERROR => $e");
      return false;
    }
  }

  Future<bool> updateSenderAddress({
    required int addressId,
    required String senderName,
    required String phoneNumber,
    required String address,
    String? landmark,
    int? district,
    int? state,
    int? country,
    String? zipCode,
    required String latitude,
    required String longitude,
  }) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/users/addresses/update/$addressId/",
    );
    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "sender_name": senderName,
          "phone_number": phoneNumber,
          "address": address,
          "landmark": landmark,
          "district": district,
          "state": state,
          "country": country,
          "zip_code": zipCode,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      logger.i("UPDATE SENDER STATUS => ${response.statusCode}");
      logger.i("UPDATE SENDER BODY => ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e("UPDATE SENDER ERROR => $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getReceiverAddressByPickupId(
    int pickupId,
  ) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/receiver/address/update/$pickupId/",
    );
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );
      logger.i("GET RECEIVER STATUS => ${response.statusCode}");
      logger.i("GET RECEIVER BODY => ${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      logger.e("GET RECEIVER ERROR => $e");
    }

    return null;
  }

  Future<bool> updateReceiverAddress({
    required int addressId,
    required String receiverName,
    required String phoneNumber,
    required String address,
    String? landmark,
    required int? productId,
    required int? receiverId,
    int? district,
    int? state,
    int? country,
    String? zipCode,
    required String latitude,
    required String longitude,
  }) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/receiver/address/update/$addressId/",
    );
    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "product_id": productId,
          "receiver": receiverId,
          "receiver_name": receiverName,
          "receiver_phone": phoneNumber,
          "address_text": address,
          "landmark": landmark,
          "district": district,
          "state": state,
          "country": country,
          "zip_code": zipCode,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );
      debugPrint("UPDATE RECEIVER STATUS: ${response.statusCode}");
      debugPrint("UPDATE RECEIVER BODY: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("UPDATE RECEIVER ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteReceiverAddress({required int addressId}) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/receiver/address/update/$addressId/",
    );

    try {
      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<OrderModel>> getAllOrders({int? deliveryModeId}) async {
    try {
      Uri uri;
      if (deliveryModeId != null) {
        uri = Uri.parse(
          '$baseurl/api/qdel/user/view/all/orders/?delivery_mode=$deliveryModeId',
        );
        debugPrint("🔍 Filtering orders by delivery mode: $deliveryModeId");
      } else {
        uri = Uri.parse('$baseurl/api/qdel/user/view/all/orders/');
        debugPrint("📋 Fetching all orders (no filter)");
      }

      final response = await http.get(
        uri,
        headers: {'Authorization': "Bearer ${ApiService.accessToken}"},
      );
      debugPrint("💡 GET ORDERS STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
        return [];
      }

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("❌ Failed to decode JSON: $e");
        debugPrint("❌ Raw response: ${response.body}");
        return [];
      }

      if (decoded['status'] != 'success') {
        debugPrint("⚠️ API returned non-success status: ${decoded['status']}");
        return [];
      }

      final List ordersJson = decoded['data'];
      if (ordersJson.isEmpty) {
        debugPrint("📭 No orders found in response");
        return [];
      }

      debugPrint("📦 Total orders from API: ${ordersJson.length}");

      final List<OrderModel> orders = [];
      int parseErrors = 0;

      for (var orderJson in ordersJson) {
        try {
          final order = OrderModel.fromJson(orderJson);
          orders.add(order);
          debugPrint("✅ Order ${order.id} parsed successfully");
          if (order.senderAddress != null) {
            final lat = order.senderAddress!.latitude;
            final lng = order.senderAddress!.longitude;
            if (lat != null && lng != null) {
              debugPrint("   📍 Has coordinates: ($lat, $lng)");
            } else {
              debugPrint("   ⚠️ Missing coordinates");
            }
          } else {
            debugPrint("   ⚠️ No sender address");
          }
        } catch (e, stackTrace) {
          parseErrors++;
          debugPrint(
            "⚠️ Failed to parse order ${orderJson['id'] ?? 'unknown'}: $e",
          );
          if (orderJson.containsKey('product_details')) {
            debugPrint("   product_details: ${orderJson['product_details']}");
          }
          if (orderJson.containsKey('sender_address')) {
            debugPrint("   sender_address: ${orderJson['sender_address']}");
          }
          if (parseErrors <= 3) {
            debugPrint("   Stack trace: $stackTrace");
          }

          continue;
        }
      }
      debugPrint(
        "✅ Successfully parsed ${orders.length} out of ${ordersJson.length} orders",
      );
      if (parseErrors > 0) {
        debugPrint("⚠️ Failed to parse $parseErrors orders");
      }
      return orders;
    } catch (e) {
      debugPrint("⛔ GET ORDERS ERROR => $e");
      return [];
    }
  }

  Future<LatLng?> getCarrierCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  Future<Map<String, dynamic>?> createPickupRequest({
    required int deliverymodeId,
    required int productId,
    required int senderAddressId,
    required int receiverAddressId,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/users/sent/request/");

    final body = {
      "delivery_mode": deliverymodeId,
      "product": productId,
      "address": senderAddressId,
      "receiver_address": receiverAddressId,
    };
    logger.i("CREATE PICKUP URL => $url");
    logger.i("CREATE PICKUP BODY => $body");
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      logger.i("CREATE PICKUP STATUS => ${response.statusCode}");
      logger.i("CREATE PICKUP RESPONSE => ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          logger.i("Delivery mode in response: ${data['delivery_mode']}");
          if (data['delivery_mode'] == null) {
            logger.w("⚠️ Delivery mode was not saved in the backend!");
          } else {
            logger.i(
              "✅ Delivery mode saved successfully: ${data['delivery_mode']}",
            );
          }
        }
        return responseData;
      } else {
        logger.e("CREATE PICKUP FAILED => ${response.body}");
        return null;
      }
    } catch (e) {
      logger.e("CREATE PICKUP ERROR => $e");
      return null;
    }
  }

  int? lastAcceptedPickupCarrierId;

  Future<Map<String, dynamic>?> acceptOrder({
  required int pickupId,
  required double latitude,
  required double longitude,
}) async {
  Uri uri = Uri.parse("$baseurl/api/qdel/users/pickups/carrier/request/");
  final headers = {
    "Authorization": "Bearer ${ApiService.accessToken}",
    "Content-Type": "application/json",
  };
  final body = jsonEncode({
    "pickup": pickupId,
    "latitude": latitude,
    "longitude": longitude,
  });
  try {
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData['data'] != null && responseData['data']['id'] != null) {
        lastAcceptedPickupCarrierId = responseData['data']['id'];
        // Always clear stale ID before saving fresh one
        await clearPickupCarrierId();
        await savePickupCarrierId(lastAcceptedPickupCarrierId!);
        logger.i("✅ Saved fresh pickup_carrier_id: $lastAcceptedPickupCarrierId");
      }
      return responseData;
    } else {
      logger.e("❌ ACCEPT ORDER FAILED => ${response.body}");
      return null;
    }
  } catch (e) {
    logger.e("❌ ACCEPT ORDER ERROR => $e");
    return null;
  }
}

  // Future<Map<String, dynamic>?> acceptOrder({
  //   required int pickupId,
  //   required double latitude,
  //   required double longitude,
  // }) async {
  //   Uri uri = Uri.parse("$baseurl/api/qdel/users/pickups/carrier/request/");
  //   final headers = {
  //     "Authorization": "Bearer ${ApiService.accessToken}",
  //     "Content-Type": "application/json",
  //   };
  //   final body = jsonEncode({
  //     "pickup": pickupId,
  //     "latitude": latitude,
  //     "longitude": longitude,
  //   });
  //   try {
  //     final response = await http.post(uri, headers: headers, body: body);

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final responseData = jsonDecode(response.body);

  //       if (responseData['data'] != null &&
  //           responseData['data']['id'] != null) {
  //         lastAcceptedPickupCarrierId = responseData['data']['id'];
  //         logger.i(
  //           "✅ Captured pickup_carrier_id: $lastAcceptedPickupCarrierId",
  //         );
  //         await savePickupCarrierId(lastAcceptedPickupCarrierId!);
  //       }

  //       return responseData;
  //     } else {
  //       logger.e("❌ ACCEPT ORDER FAILED => ${response.body}");
  //       return null;
  //     }
  //   } catch (e) {
  //     logger.e("❌ ACCEPT ORDER ERROR => $e");
  //     return null;
  //   }
  // }

  static Future<void> savePickupCarrierId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("pickup_carrier_id", id);
    debugPrint("✅ Saved pickup_carrier_id: $id");
  }

  static Future<int?> getPickupCarrierId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("pickup_carrier_id");
  }

  static Future<void> clearPickupCarrierId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("pickup_carrier_id");
  }

  Future<dynamic> getAcceptedOrders({
    int? page,
    String? search,
    String? status,
  }) async {
    String urlString = "$baseurl/api/qdel/sender/view/sent/orders/";
    List<String> queryParams = [];

    if (page != null) {
      queryParams.add("page=$page");
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add("search=$search");
    }
    if (status != null && status.isNotEmpty) {
      queryParams.add("status=$status");
    }

    if (queryParams.isNotEmpty) {
      urlString += "?" + queryParams.join("&");
    }

    final uri = Uri.parse(urlString);
    final headers = {
      "Authorization": "Bearer ${ApiService.accessToken}",
      "Content-Type": "application/json",
    };

    try {
      print("📡 Fetching accepted orders - URL: $urlString");
      final response = await http.get(uri, headers: headers);

      print("📦 ACCEPTED ORDERS STATUS :: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return data;
      } else {
        print("❌ GET ACCEPTED ORDERS FAILED => ${response.body}");
        throw Exception(
          "Failed to load accepted orders (Status: ${response.statusCode})",
        );
      }
    } catch (e) {
      print("🔥 GET ACCEPTED ORDERS ERROR => $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSenderDetails(int pickupId) async {
    final url = Uri.parse("$baseurl/api/qdel/user/sender/details/$pickupId/");
    try {
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      logger.e("SENDER ERROR => $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getReceiverDetails(int pickupId) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/user/sender/receiver/details/$pickupId/",
    );

    try {
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      logger.e("RECEIVER ERROR => $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProductDetails(int pickupId) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/user/sender/product/details/$pickupId/",
    );
    try {
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      logger.e("PRODUCT ERROR => $e");
    }
    return null;
  }

  static Future<int?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('user_id');
}

  Future<Map<String, dynamic>?> getShipmentStatus(int pickupId) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/sender/shipment-status/$pickupId/",
    );
    try {
      final res = await http.get(url, headers: _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      logger.e("SHIPMENT ERROR => $e");
    }
    return null;
  }

  Map<String, String> _headers() => {
    "Authorization": "Bearer ${ApiService.accessToken}",
    "Content-Type": "application/json",
  };

  Future<Map<String, dynamic>?> cancelOrder({required int pickupId}) async {
    final url = Uri.parse("$baseurl/api/qdel/sender/cancel/pickup/$pickupId/");

    try {
      final response = await http.patch(url, headers: _headers());

      logger.i("CANCEL ORDER URL :: $url");
      logger.i("CANCEL ORDER STATUS :: ${response.statusCode}");
      logger.i("CANCEL ORDER RESPONSE :: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {"success": true};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['message'] ?? errorData['error'] ?? "Unknown error",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to cancel order with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("CANCEL ORDER EXCEPTION :: $e");
      return {"success": false, "error": "Exception: $e"};
    }
  }

  static Future<void> saveActiveOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("active_order_id", orderId);
  }

  static Future<int?> getActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("active_order_id");
  }

  static Future<void> clearActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("active_order_id");
  }

  static Future<void> saveActiveDropId(int dropId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("active_drop_id", dropId);
    debugPrint("✅ Saved active drop ID: $dropId");
  }

  static Future<int?> getActiveDropId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("active_drop_id");
  }

  static Future<void> clearActiveDropId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("active_drop_id");
    debugPrint("🗑️ Cleared active drop ID");
  }

  Future<OrderModel?> fetchOrderById(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseurl/api/qdel/user/view/all/orders/'),
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("FETCH ORDER BY ID STATUS :: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (decoded['status'] == 'success') {
          final List ordersJson = decoded['data'];
          final orderJson = ordersJson.firstWhere(
            (order) => order['id'] == orderId,
            orElse: () => null,
          );

          if (orderJson != null) {
            logger.i("✅ Order found: $orderId");
            return OrderModel.fromJson(orderJson);
          } else {
            logger.e("❌ Order not found with ID: $orderId");
          }
        }
      }
      return null;
    } catch (e) {
      logger.e("❌ FETCH ORDER BY ID ERROR => $e");
      return null;
    }
  }

  static Future<void> saveActiveOrderDetails(OrderModel order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderJson = jsonEncode(order.toJson());
      await prefs.setString('active_order_details', orderJson);
      debugPrint("✅ Saved order details for ID: ${order.id}");
    } catch (e) {
      debugPrint("❌ Error saving order details: $e");
    }
  }

  static Future<OrderModel?> getActiveOrderDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString('active_order_details');

    if (orderJson != null) {
      try {
        return OrderModel.fromJson(jsonDecode(orderJson));
      } catch (e) {
        debugPrint("Error parsing cached order: $e");
        return null;
      }
    }
    return null;
  }

  static Future<void> clearActiveOrderDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_order_details');
  }

  Future<Map<String, dynamic>?> markArrivedSimple({
    required int pickupCarrierId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/arrived/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("🚚 MARK ARRIVED URL => $url");
      logger.i("📤 MARK ARRIVED HEADERS => $headers");

      final response = await http.patch(url, headers: headers);

      logger.i("📥 MARK ARRIVED STATUS => ${response.statusCode}");
      logger.i("📥 MARK ARRIVED RESPONSE => ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
          "statusCode": response.statusCode,
        };
      } else {
        logger.e("❌ MARK ARRIVED FAILED => ${response.body}");
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to mark arrival",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to mark arrival with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ MARK ARRIVED EXCEPTION => $e");
      return {"success": false, "error": "Exception: $e"};
    }
  }

  Future<Map<String, dynamic>?> sendPickupOtp({
    required int pickupCarrierId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/request/otp/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("SEND PICKUP OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: {} (no fields required)");

      final response = await http.post(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ OTP sent successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e("❌ SEND OTP FAILED with status ${response.statusCode}");
        logger.e("❌ Response body: ${response.body}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to send OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error": "Failed to send OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ SEND OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> verifyPickupOtp({
    required int pickupCarrierId,
    required String otp,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/verify/otp/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({"otp": otp});

      logger.i("=" * 80);
      logger.i("VERIFY PICKUP OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ OTP verified successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e("❌ VERIFY OTP FAILED with status ${response.statusCode}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to verify OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error": "Failed to verify OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ VERIFY OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  static Future<void> saveArrivalStatus(int orderId, bool isArrived) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arrived_$orderId', isArrived);
    debugPrint("✅ Saved arrival status for order $orderId: $isArrived");
  }

  static Future<bool?> getArrivalStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('arrived_$orderId');
  }

  static Future<void> saveOtpSentStatus(int orderId, bool isOtpSent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('otp_sent_$orderId', isOtpSent);
    debugPrint("✅ Saved OTP sent status for order $orderId: $isOtpSent");
  }

  static Future<bool?> getOtpSentStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('otp_sent_$orderId');
  }

  static Future<void> saveVerificationStatus(
    int orderId,
    bool isVerified,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verified_$orderId', isVerified);
    debugPrint("✅ Saved verification status for order $orderId: $isVerified");
  }

  static Future<bool?> getVerificationStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('verified_$orderId');
  }

  Future<Map<String, dynamic>?> markDelivered({
    required int pickupCarrierId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/arrived/droplocation/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("MARK DELIVERED DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");

      final response = await http.patch(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Delivery marked successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e("❌ MARK DELIVERED FAILED with status ${response.statusCode}");
        logger.e("❌ Response body: ${response.body}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to mark delivery",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to mark delivery with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ MARK DELIVERED EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> sendDeliveryOtp({
    required int pickupCarrierId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/delivery/send/otp/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("SEND DELIVERY OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: {} (no fields required)");

      final response = await http.post(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Delivery OTP sent successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ SEND DELIVERY OTP FAILED with status ${response.statusCode}",
        );
        logger.e("❌ Response body: ${response.body}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to send delivery OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to send delivery OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ SEND DELIVERY OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> verifyDeliveryOtp({
    required int pickupCarrierId,
    required String otp,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/delivery/verify/otp/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({"otp": otp});

      logger.i("=" * 80);
      logger.i("VERIFY DELIVERY OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Delivery OTP verified successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ VERIFY DELIVERY OTP FAILED with status ${response.statusCode}",
        );

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to verify delivery OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to verify delivery OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ VERIFY DELIVERY OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  static Future<void> saveDeliveryArrivalStatus(
    int orderId,
    bool hasArrived,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delivery_arrived_$orderId', hasArrived);
    debugPrint(
      "✅ Saved delivery arrival status for order $orderId: $hasArrived",
    );
  }

  static Future<bool?> getDeliveryArrivalStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('delivery_arrived_$orderId');
  }

  static Future<void> saveDeliveryOtpSentStatus(
    int orderId,
    bool isOtpSent,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delivery_otp_sent_$orderId', isOtpSent);
    debugPrint(
      "✅ Saved delivery OTP sent status for order $orderId: $isOtpSent",
    );
  }

  static Future<bool?> getDeliveryOtpSentStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('delivery_otp_sent_$orderId');
  }

  static Future<void> saveDeliveryVerifiedStatus(
    int orderId,
    bool isVerified,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delivery_verified_$orderId', isVerified);
    debugPrint(
      "✅ Saved delivery verified status for order $orderId: $isVerified",
    );
  }

  static Future<bool?> getDeliveryVerifiedStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('delivery_verified_$orderId');
  }

  static Future<void> clearOrderStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('arrived_$orderId');
    await prefs.remove('otp_sent_$orderId');
    await prefs.remove('verified_$orderId');
    await prefs.remove('delivery_arrived_$orderId');
    await prefs.remove('delivery_otp_sent_$orderId');
    await prefs.remove('delivery_verified_$orderId');
    debugPrint("🗑️ Cleared all status for order $orderId");
  }

  Future<Map<String, dynamic>?> getCarrierLiveLocation({
    required int id,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/sender/carrier/live/location/$id/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("GET CARRIER LIVE LOCATION DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");

      final response = await http.get(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Carrier live location fetched successfully");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else if (response.statusCode == 404) {
        logger.e("❌ Carrier location not found for ID: $id");
        return {
          "success": false,
          "error": "Carrier location not found",
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ GET CARRIER LOCATION FAILED with status ${response.statusCode}",
        );
        logger.e("❌ Response body: ${response.body}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to get carrier location",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to get carrier location with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ GET CARRIER LIVE LOCATION EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> updateCarrierLocation({
    required int pickupCarrierId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/users/pickups/carrier/update/$pickupCarrierId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": DateTime.now().toIso8601String(),
      });

      logger.i("=" * 80);
      logger.i("UPDATE CARRIER LOCATION DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: $body");

      final response = await http.put(url, headers: headers, body: body);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Carrier location updated successfully");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e("❌ UPDATE LOCATION FAILED with status ${response.statusCode}");
        logger.e("❌ Response body: ${response.body}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to update location",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to update location with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ UPDATE LOCATION EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  static Future<void> savePickupCarrierIdForOrder(
    int orderId,
    int pickupCarrierId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("order_${orderId}_carrier_id", pickupCarrierId);
    debugPrint("✅ Saved pickup_carrier_id $pickupCarrierId for order $orderId");
  }

  static Future<int?> getPickupCarrierIdForOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("order_${orderId}_carrier_id");
  }

  Future<Map<String, dynamic>> getCarrierCompletedOrders({
    int? page,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 10,
  }) async {
    try {
      String urlString = "$baseurl/api/qdel/carrier/dashboard/";
      final queryParams = <String>[];

      if (page != null) {
        queryParams.add("page=$page");
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add("search=$search");
      }
      if (startDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(startDate);
        queryParams.add("start_date=$formattedDate");
      }
      if (endDate != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(endDate);
        queryParams.add("end_date=$formattedDate");
      }
      queryParams.add("page_size=$pageSize");

      if (queryParams.isNotEmpty) {
        urlString += "?" + queryParams.join("&");
      }

      final uri = Uri.parse(urlString);
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("📡 FETCHING CARRIER COMPLETED ORDERS - URL: $urlString");

      final response = await http.get(uri, headers: headers);

      logger.i("📦 CARRIER COMPLETED ORDERS STATUS :: ${response.statusCode}");
      logger.i("📦 CARRIER COMPLETED ORDERS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        List<CompletedOrder> orders = [];

        if (jsonResponse.containsKey('results') &&
            jsonResponse['results'] is List) {
          orders = (jsonResponse['results'] as List)
              .map((json) => CompletedOrder.fromJson(json))
              .toList();
        }

        int totalCount = jsonResponse['count'] ?? 0;
        if (totalCount is String) {
          totalCount = totalCount;
        }

        String? nextUrl = jsonResponse['next'];
        String? previousUrl = jsonResponse['previous'];

        bool hasNext = nextUrl != null && nextUrl.isNotEmpty;
        bool hasPrevious = previousUrl != null && previousUrl.isNotEmpty;

        int totalPages;
        if (hasNext) {
          totalPages = (totalCount / pageSize).ceil();
          if (totalPages < 2 && hasNext) {
            totalPages = 2;
          }
        } else {
          totalPages = (totalCount / pageSize).ceil();
          if (totalPages < 1) totalPages = 1;
        }

        logger.i("✅ Successfully fetched ${orders.length} completed orders");
        logger.i("📊 Page ${page ?? 1} of $totalPages (Total: $totalCount)");
        logger.i("📊 Has Next: $hasNext, Has Previous: $hasPrevious");

        return {
          'orders': orders,
          'hasNext': hasNext,
          'hasPrevious': hasPrevious,
          'totalPages': totalPages,
          'currentPage': page ?? 1,
          'count': totalCount,
          'nextUrl': nextUrl,
          'previousUrl': previousUrl,
        };
      } else if (response.statusCode == 401) {
        logger.e("❌ Unauthorized - Token expired or invalid");
        throw Exception("Unauthorized - Please login again");
      } else {
        logger.e("❌ Failed to fetch completed orders: ${response.statusCode}");

        try {
          final errorData = jsonDecode(response.body);
          return {
            'orders': [],
            'hasNext': false,
            'hasPrevious': false,
            'totalPages': 1,
            'currentPage': page ?? 1,
            'count': 0,
            'error':
                errorData['detail'] ??
                errorData['message'] ??
                'Failed to fetch completed orders',
          };
        } catch (_) {
          return {
            'orders': [],
            'hasNext': false,
            'hasPrevious': false,
            'totalPages': 1,
            'currentPage': page ?? 1,
            'count': 0,
            'error':
                'Failed to fetch completed orders with status ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      logger.e("🔥 CARRIER COMPLETED ORDERS ERROR => $e");
      return {
        'orders': [],
        'hasNext': false,
        'hasPrevious': false,
        'totalPages': 1,
        'currentPage': page ?? 1,
        'count': 0,
        'error': 'Exception: $e',
      };
    }
  }

  Future<CompletedOrder?> getCarrierOrderDetail(int id) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/carrier/dashboard/detail/$id/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("📡 FETCHING CARRIER ORDER DETAIL - URL: $url");

      final response = await http.get(url, headers: headers);

      logger.i("📦 CARRIER ORDER DETAIL STATUS :: ${response.statusCode}");
      logger.i("📦 CARRIER ORDER DETAIL BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('results') &&
            jsonResponse['results'] is List) {
          final results = jsonResponse['results'] as List;
          if (results.isNotEmpty) {
            return CompletedOrder.fromJson(results.first);
          }
        } else {
          return CompletedOrder.fromJson(jsonResponse);
        }
      }
      return null;
    } catch (e) {
      logger.e("🔥 CARRIER ORDER DETAIL ERROR => $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getCarrierDashboardCounts() async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/carrier/dashboard/count/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("📡 FETCHING CARRIER DASHBOARD COUNTS - URL: $url");
      logger.i("📡 HEADERS: $headers");

      final response = await http.get(url, headers: headers);

      logger.i("📦 CARRIER DASHBOARD COUNTS STATUS :: ${response.statusCode}");
      logger.i("📦 CARRIER DASHBOARD COUNTS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        logger.i("✅ Successfully parsed counts: $data");

        return {
          'totalCompleted': data['total_completed_count'] ?? 0,
          'todayCompleted': data['today_completed_count'] ?? 0,
          'success': true,
        };
      } else {
        logger.e("❌ Failed to fetch dashboard counts: ${response.statusCode}");
        logger.e("❌ Response body: ${response.body}");

        return {
          'totalCompleted': 0,
          'todayCompleted': 0,
          'success': false,
          'error': 'Failed to load counts: ${response.statusCode}',
        };
      }
    } catch (e) {
      logger.e("🔥 CARRIER DASHBOARD COUNTS ERROR => $e");
      return {
        'totalCompleted': 0,
        'todayCompleted': 0,
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardCounts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      String urlString =
          "$baseurl/api/qdel/admin/dashboard/count/?start_date=$formattedStartDate&end_date=$formattedEndDate";

      final uri = Uri.parse(urlString);
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("📡 FETCHING ADMIN DASHBOARD COUNTS - URL: $urlString");

      final response = await http.get(uri, headers: headers);

      logger.i("📦 ADMIN DASHBOARD COUNTS STATUS :: ${response.statusCode}");
      logger.i("📦 ADMIN DASHBOARD COUNTS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        logger.i("✅ Successfully fetched admin dashboard counts");

        return {
          'ongoing_deliveries': jsonResponse['ongoing_deliveries'] ?? 0,
          'completed_deliveries': jsonResponse['completed_deliveries'] ?? 0,
          'total_users': jsonResponse['total_users'] ?? 0,
          'verified_carriers': jsonResponse['verified_carriers'] ?? 0,
          'total_ongoing_deliveries':
              jsonResponse['total_ongoing_deliveries'] ?? 0,
          'total_completed_deliveries':
              jsonResponse['total_completed_deliveries'] ?? 0,
          'total_users_all': jsonResponse['total_users_all'] ?? 0,
          'total_verified_carriers':
              jsonResponse['total_verified_carriers'] ?? 0,
          'success': true,
        };
      } else if (response.statusCode == 401) {
        logger.e("❌ Unauthorized - Token expired or invalid");
        throw Exception("Unauthorized - Please login again");
      } else {
        logger.e(
          "❌ Failed to fetch admin dashboard counts: ${response.statusCode}",
        );
        throw Exception("Failed to fetch dashboard data");
      }
    } catch (e) {
      logger.e("🔥 ADMIN DASHBOARD COUNTS ERROR => $e");
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> sendOldPhoneOtp({
    required String newPhone,
  }) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/phone-change/send/old/otp/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({"new_phone": newPhone});

      logger.i("📡 SENDING OLD PHONE OTP - URL: $url");
      logger.i("📡 BODY: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📦 OLD PHONE OTP STATUS :: ${response.statusCode}");
      logger.i("📦 OLD PHONE OTP BODY :: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to send OTP to old number");
      }
    } catch (e) {
      logger.e("🔥 OLD PHONE OTP ERROR => $e");
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> verifyOldPhoneOtp({
    required String newPhone,
    required String otp,
  }) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/phone-change/verify/old/otp/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({"new_phone": newPhone, "otp_old": otp});

      logger.i("📡 VERIFYING OLD PHONE OTP - URL: $url");
      logger.i("📡 BODY: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📦 OLD PHONE VERIFY STATUS :: ${response.statusCode}");
      logger.i("📦 OLD PHONE VERIFY BODY :: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Invalid OTP");
      }
    } catch (e) {
      logger.e("🔥 OLD PHONE VERIFY ERROR => $e");
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> sendNewPhoneOtp({
    required String newPhone,
  }) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/phone-change/send/new/otp/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({"new_phone": newPhone});

      logger.i("📡 SENDING NEW PHONE OTP - URL: $url");
      logger.i("📡 BODY: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📦 NEW PHONE OTP STATUS :: ${response.statusCode}");
      logger.i("📦 NEW PHONE OTP BODY :: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to send OTP to new number");
      }
    } catch (e) {
      logger.e("🔥 NEW PHONE OTP ERROR => $e");
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> verifyNewPhoneOtp({
    required String newPhone,
    required String otp,
  }) async {
    try {
      final url = Uri.parse("$baseurl/api/qdel/phone-change/verify/new/otp/");
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };
      final body = jsonEncode({"new_phone": newPhone, "otp_new": otp});

      logger.i("📡 VERIFYING NEW PHONE OTP - URL: $url");
      logger.i("📡 BODY: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📦 NEW PHONE VERIFY STATUS :: ${response.statusCode}");
      logger.i("📦 NEW PHONE VERIFY BODY :: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Invalid OTP");
      }
    } catch (e) {
      logger.e("🔥 NEW PHONE VERIFY ERROR => $e");
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> submitComplaint(ComplaintModel complaint) async {
    try {
      final token = ApiService.accessToken;
      final Uri url = Uri.parse('$baseurl/api/qdel/sender/customer-service/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(complaint.toJson()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        String errorMessage = 'Failed to submit complaint';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              errorData['detail'] ??
              errorMessage;
        } catch (e) {
          errorMessage =
              'Error ${response.statusCode}: ${response.reasonPhrase}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet connection');
      } else {
        logger.e('❌ Unknown error type: ${e.runtimeType}');
        throw Exception('Failed to submit complaint: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>?> cancelPickupOrder(int pickupCarrierId) async {
    try {
      final url = Uri.parse(
        '$baseurl/api/qdel/carrier/cancel/pickup/$pickupCarrierId/',
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final response = await http.patch(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['detail'] ?? 'Failed to cancel order',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List> getShopCategories({String? search}) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/user/view/shop/categories/"
      "${search != null && search.isNotEmpty ? "?search=$search" : ""}",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("STATUS :: ${response.statusCode}");
      logger.i("BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List categories = json['data'] ?? [];
        return categories;
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      logger.e("❌ Error fetching categories: $e");
      rethrow;
    }
  }

  Future<bool> addCategory(String name) async {
    final url = Uri.parse("$baseurl/api/qdel/user/view/shop/categories/");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"name": name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception("Error adding category: $e");
    }
  }

  Future<String?> checkShopApprovalStatus() async {
    try {
      final response = await http.get(
        Uri.parse("$baseurl/api/qdel/register/"),
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i("SHOP STATUS CHECK :: ${response.statusCode}");
      logger.i("SHOP STATUS BODY :: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List users = decoded["data"];
        final myPhone = ApiService.phone;
        final myUser = users.firstWhere(
          (u) => u["phone"] == myPhone,
          orElse: () => null,
        );

        if (myUser == null) return null;

        return myUser["shop_approval_status"] ?? myUser["approval_status"];
      }
      return null;
    } catch (e) {
      logger.e("SHOP STATUS ERROR => $e");
      return null;
    }
  }

  Future<bool> updateUserrRegistration({
    String? shopName,
    int? shopCategories,

    File? document,
    File? carrierPhoto,
    File? shopPhoto,
    File? ownerShopPhoto,
    File? shopDocument,

    String? address,
    String? landmark,
    String? zipCode,
    double? latitude,
    double? longitude,

    int? shopDistrictId,
    int? shopStateId,
    int? shopCountryId,
  }) async {
    try {
      logger.i("🔄 Updating carrier registration with PUT request");

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseurl/api/qdel/register/update/view/'),
      );

      request.headers.addAll({
        'Authorization': "Bearer ${ApiService.accessToken}",
        'Accept': 'application/json',
      });

      if (shopName != null) request.fields['shop_name'] = shopName;
      if (shopCategories != null) {
        request.fields['shop_categories'] = shopCategories.toString();
      }
      if (address != null) request.fields['address'] = address;
      if (landmark != null) request.fields['landmark'] = landmark;
      if (zipCode != null) request.fields['zip_code'] = zipCode;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (shopDistrictId != null) {
        request.fields['shop_district_id'] = shopDistrictId.toString();
      }
      if (shopStateId != null) {
        request.fields['shop_state_id'] = shopStateId.toString();
      }
      if (shopCountryId != null) {
        request.fields['shop_country_id'] = shopCountryId.toString();
      }

      if (document != null) {
        request.files.add(
          await http.MultipartFile.fromPath('document', document.path),
        );
      }

      if (carrierPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('carrier_photo', carrierPhoto.path),
        );
      }

      if (shopPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('shop_photo', shopPhoto.path),
        );
      }

      if (ownerShopPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'owner_shop_photo',
            ownerShopPhoto.path,
          ),
        );
      }

      if (shopDocument != null) {
        request.files.add(
          await http.MultipartFile.fromPath('shop_document', shopDocument.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      logger.i("📡 Response status code: ${response.statusCode}");
      logger.i("📡 Response body: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final Map<String, dynamic> responseData = json.decode(responseBody);
        logger.i("✅ User updated successfully");
        return true;
      } else {
        logger.e(
          "❌ Failed to update carrier registration. Status: ${response.statusCode}",
        );
        return false;
      }
    } catch (e, stackTrace) {
      logger.e(
        "❌ Error updating carrier registration",
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> createComplaint({
    required String subject,
    required String description,
  }) async {
    final url = Uri.parse('$baseurl/api/qdel/user/complaints/create/');

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"subject": subject, "description": description}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Complaint submitted successfully");
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 Error: $e");
      return false;
    }
  }

  Future<bool> createShopStatus({required bool isManuallyClosed}) async {
    final url = Uri.parse("$baseurl/api/qdel/shop/create/time/");

    final body = {"is_manually_closed": isManuallyClosed};

    print("========== API DEBUG START ==========");
    print("URL: $url");
    print("BODY: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      print("========== API DEBUG END ==========");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ EXCEPTION: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getShopTimings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseurl/api/qdel/shop/create/time/'),
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        return decoded;
      }

      return null;
    } catch (e) {
      print('Error fetching shop timings: $e');
      return null;
    }
  }

  Future<bool> createShopTimings({
    required List<WorkingDay> workingDays,
    required List<SpecialDay> specialDays,
    required bool isManuallyClosed,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'is_manually_closed': isManuallyClosed,
        'working_days': workingDays.map((d) => d.toJson()).toList(),
        'special_days': specialDays.map((d) => d.toJson()).toList(),
      };
      print('Creating shop timings with special days: ${specialDays.length}');
      print('Request body: ${json.encode(body)}');
      final response = await http.post(
        Uri.parse('$baseurl/api/qdel/shop/create/time/'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating shop timings: $e');
      return false;
    }
  }

  Future<bool> updateShopTimings({
    required int? shopId,
    required List<WorkingDay> workingDays,
    required List<SpecialDay> specialDays,
    required bool isManuallyClosed,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'is_manually_closed': isManuallyClosed,
        'working_days': workingDays.map((d) => d.toJson()).toList(),
        'special_days': specialDays.map((d) => d.toJson()).toList(),
      };
      print('Updating shop timings with special days: ${specialDays.length}');
      print('Request body: ${json.encode(body)}');
      final url = '$baseurl/api/qdel/shop/update/shop/time/';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating shop timings: $e');
      return false;
    }
  }

  Future<bool> deleteSpecialDay(int specialDayId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseurl/api/qdel/shop/special/day/$specialDayId/'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      print('Delete special day response status: ${response.statusCode}');
      print('Delete special day response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting special day: $e');
      return false;
    }
  }

  Future<List<DeliveryMode>> getDeliveryModes({bool fetchAll = true}) async {
    List<DeliveryMode> allModes = [];
    String? nextUrl = '$baseurl/api/qdel/admin/add/delivery/modes/';

    try {
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "application/json",
          },
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> items = data['data'] ?? [];
          final modes = items
              .map((item) => DeliveryMode.fromJson(item))
              .toList();
          allModes.addAll(modes);
          nextUrl = fetchAll ? data['next'] : null;
        } else {
          break;
        }
      }

      return allModes;
    } catch (e) {
      print('Error fetching delivery modes: $e');
      return allModes;
    }
  }

  Future<bool> createDeliveryMode(String name, String descriptionMode) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        "description": descriptionMode,
      };

      final response = await http.post(
        Uri.parse('$baseurl/api/qdel/admin/add/delivery/modes/'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );

      print('POST delivery mode response: ${response.statusCode}');
      print('POST delivery mode body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating delivery mode: $e');
      return false;
    }
  }

  Future<bool> updateDeliveryMode(
    int id,
    String name,
    String descriptionMode,
  ) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'description': descriptionMode,
      };

      final response = await http.put(
        Uri.parse('$baseurl/api/qdel/admin/update/delivery/modes/$id/'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );

      print('PUT delivery mode response: ${response.statusCode}');
      print('PUT delivery mode body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating delivery mode: $e');
      return false;
    }
  }

  Future<bool> deleteDeliveryMode(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseurl/api/qdel/admin/update/delivery/modes/$id/'),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      print('DELETE delivery mode response: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting delivery mode: $e');
      return false;
    }
  }

  Future<List<DropLocation>> getDropLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseurl/api/qdel/user/shop/addresses/view/'),
        headers: {
          'Authorization': "Bearer ${ApiService.accessToken}",
          'Content-Type': 'application/json',
        },
      );

      debugPrint("💡 GET DROP LOCATIONS STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
        debugPrint("❌ Response body: ${response.body}");
        return [];
      }

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("❌ Failed to decode JSON: $e");
        return [];
      }

      if (decoded['status'] != 'success') {
        debugPrint("⚠️ API returned non-success status: ${decoded['status']}");
        return [];
      }

      final List locationsJson = decoded['data'];
      if (locationsJson.isEmpty) {
        debugPrint("📭 No drop locations found");
        return [];
      }

      debugPrint("📦 Total drop locations from API: ${locationsJson.length}");

      final List<DropLocation> dropLocations = [];
      for (var locationJson in locationsJson) {
        try {
          final location = DropLocation.fromJson(locationJson);
          dropLocations.add(location);
          debugPrint("✅ Drop location ${location.id} parsed successfully");
        } catch (e) {
          debugPrint("⚠️ Failed to parse drop location: $e");
          continue;
        }
      }

      debugPrint(
        "✅ Successfully parsed ${dropLocations.length} drop locations",
      );
      return dropLocations;
    } catch (e) {
      debugPrint("⛔ GET DROP LOCATIONS ERROR => $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getShopDropAddress(int shopDropId) async {
    final url = Uri.parse("$baseurl/api/qdel/shop/drop/address/$shopDropId/");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${ApiService.accessToken}",
        },
      );

      print("GET SHOP DROP ADDRESS STATUS: ${response.statusCode}");
      print("GET SHOP DROP ADDRESS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded;
      } else {
        return null;
      }
    } catch (e) {
      print("ERROR in getShopDropAddress: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> acceptShop(
    int pickupCarrierId,
    int shopDropId,
  ) async {
    final url = Uri.parse(
      "$baseurl/api/qdel/carrier/accept/drop/$pickupCarrierId/",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${ApiService.accessToken}",
        },
        body: jsonEncode({"shop": shopDropId}),
      );

      print("ACCEPT SHOP STATUS: ${response.statusCode}");
      print("ACCEPT SHOP RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded;
      } else {
        return null;
      }
    } catch (e) {
      print("ERROR in acceptShop: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> confirmShopDropArrival(
    int pickupCarrierDropId,
  ) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/shop/$pickupCarrierDropId/arrive/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("CONFIRM SHOP DROP ARRIVAL DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: {} (no fields required)");

      final response = await http.patch(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Shop drop arrival confirmed successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ CONFIRM SHOP DROP ARRIVAL FAILED with status ${response.statusCode}",
        );

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to confirm arrival",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error":
                "Failed to confirm arrival with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ CONFIRM SHOP DROP ARRIVAL EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> uploadShopDropImage({
    required int shopDropId,
    required File image,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/carrier/shop-drop/upload/image/$shopDropId/",
      );

      var request = http.MultipartRequest('PUT', url);

      request.headers.addAll({
        "Authorization": "Bearer ${ApiService.accessToken}",
      });

      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      logger.i("=" * 80);
      logger.i("UPLOAD SHOP DROP IMAGE DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: ${request.headers}");
      logger.i("📦 File: ${image.path}");
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      logger.i("📥 RESPONSE STATUS: ${streamedResponse.statusCode}");
      logger.i("📥 RESPONSE BODY: $responseBody");

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final responseData = jsonDecode(responseBody);
        logger.i("✅ Image uploaded successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": streamedResponse.statusCode,
        };
      } else {
        logger.e(
          "❌ UPLOAD IMAGE FAILED with status ${streamedResponse.statusCode}",
        );
        return {
          "success": false,
          "error": "Failed to upload image",
          "statusCode": streamedResponse.statusCode,
        };
      }
    } catch (e) {
      logger.e("❌ UPLOAD IMAGE EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> sendShopDropOtp({
    required int shopDropId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/shop/drop/generate/otp/$shopDropId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      logger.i("=" * 80);
      logger.i("SEND SHOP DROP OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: {} (no fields required)");

      final response = await http.post(url, headers: headers);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Shop drop OTP sent successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ SEND SHOP DROP OTP FAILED with status ${response.statusCode}",
        );

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to send OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error": "Failed to send OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ SEND SHOP DROP OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  Future<Map<String, dynamic>?> verifyShopDropOtp({
    required int shopDropId,
    required String otp,
  }) async {
    try {
      final url = Uri.parse(
        "$baseurl/api/qdel/shop/drop/verify/otp/$shopDropId/",
      );

      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({"otp": otp});

      logger.i("=" * 80);
      logger.i("VERIFY SHOP DROP OTP DEBUG");
      logger.i("=" * 80);
      logger.i("📍 URL: $url");
      logger.i("🔑 Headers: $headers");
      logger.i("📦 Body: $body");

      final response = await http.post(url, headers: headers, body: body);

      logger.i("📥 RESPONSE STATUS: ${response.statusCode}");
      logger.i("📥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        logger.i("✅ Shop drop OTP verified successfully: $responseData");
        return {
          "success": true,
          "data": responseData,
          "statusCode": response.statusCode,
        };
      } else {
        logger.e(
          "❌ VERIFY SHOP DROP OTP FAILED with status ${response.statusCode}",
        );

        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "error":
                errorData['detail'] ??
                errorData['message'] ??
                "Failed to verify OTP",
            "statusCode": response.statusCode,
          };
        } catch (_) {
          return {
            "success": false,
            "error": "Failed to verify OTP with status ${response.statusCode}",
            "statusCode": response.statusCode,
          };
        }
      }
    } catch (e) {
      logger.e("❌ VERIFY SHOP DROP OTP EXCEPTION: $e");
      return {"success": false, "error": "Exception: $e"};
    } finally {
      logger.i("=" * 80);
    }
  }

  static Future<void> saveShopDropArrivalStatus(int orderId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("shop_drop_arrived_$orderId", value);
  }

  static Future<bool?> getShopDropArrivalStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("shop_drop_arrived_$orderId");
  }

  static Future<void> saveShopDropImageStatus(int orderId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("shop_drop_image_$orderId", value);
  }

  static Future<bool?> getShopDropImageStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("shop_drop_image_$orderId");
  }

  static Future<void> saveShopDropOtpSentStatus(int orderId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("shop_drop_otp_sent_$orderId", value);
  }

  static Future<bool?> getShopDropOtpSentStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("shop_drop_otp_sent_$orderId");
  }

  static Future<void> clearshopDropOrderStatus(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("shop_drop_arrived_$orderId");
    await prefs.remove("shop_drop_image_$orderId");
    await prefs.remove("shop_drop_otp_sent_$orderId");
  }

  Future<Map<String, dynamic>> getShopDropOrders({
    String? search,
    int page = 1,
    DateTime? startDate,
    DateTime? endDate,
    String? statusFilter,
  }) async {
    try {
      String urlString = "$baseurl/api/qdel/shop/orders/view/";
      final List<String> queryParams = [];

      // DEBUG: Print incoming dates
      print("🔍 RECEIVED DATES:");
      print("   startDate: $startDate");
      print("   endDate: $endDate");

      if (search != null && search.isNotEmpty) {
        queryParams.add("search=$search");
      }
      if (page > 0) {
        queryParams.add("page=$page");
      }
      if (startDate != null) {
        // Force date to UTC midnight
        final cleanDate = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final formattedDate = DateFormat('yyyy-MM-dd').format(cleanDate);
        print("🔍 CLEAN DATE: $cleanDate -> $formattedDate");
        queryParams.add("start_date=$formattedDate");
      }
      if (endDate != null) {
        final cleanDate = DateTime.utc(
          endDate.year,
          endDate.month,
          endDate.day,
        );
        final formattedDate = DateFormat('yyyy-MM-dd').format(cleanDate);
        print("🔍 CLEAN DATE: $cleanDate -> $formattedDate");
        queryParams.add("end_date=$formattedDate");
      }
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams.add("status_filter=$statusFilter");
      }

      if (queryParams.isNotEmpty) {
        urlString += "?" + queryParams.join("&");
      }

      // DEBUG: Print final URL
      print("🔍 FINAL URL: $urlString");

      // Optional: Test this URL in Postman manually

      final uri = Uri.parse(urlString);
      final headers = {
        "Authorization": "Bearer ${ApiService.accessToken}",
        "Content-Type": "application/json",
      };

      final response = await http.get(uri, headers: headers);

      print("📦 STATUS CODE: ${response.statusCode}");
      print("📦 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 401) {
        print("❌ UNAUTHORIZED - Token may be invalid or expired");
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'data': {'count': 0, 'results': []},
        };
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print("✅ Successfully parsed response");

        if (jsonResponse.containsKey('results') ||
            jsonResponse.containsKey('count')) {
          return {'success': true, 'data': jsonResponse};
        } else {
          if (jsonResponse is List) {
            return {
              'success': true,
              'data': {
                'count': jsonResponse.length,
                'results': jsonResponse,
                'next': null,
                'previous': null,
              },
            };
          }
          return {
            'success': true,
            'data': {'count': 0, 'results': [], 'next': null, 'previous': null},
          };
        }
      } else if (response.statusCode == 404) {
        print("⚠️ 404 - No orders found");
        return {
          'success': true,
          'data': {'count': 0, 'results': [], 'next': null, 'previous': null},
        };
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return {
          'success': false,
          'error': 'Failed to fetch orders: ${response.statusCode}',
          'data': {'count': 0, 'results': []},
        };
      }
    } catch (e) {
      print("🔥 EXCEPTION: $e");
      print("🔥 Stack trace: ${StackTrace.current}");
      return {
        'success': false,
        'error': 'Exception: $e',
        'data': {'count': 0, 'results': []},
      };
    }
  }

  Future<Map<String, dynamic>> getShopDropOrderDetail(int id) async {
    try {
      final url = Uri.parse('$baseurl/api/qdel/shop/orders/detail/$id/');

      logger.i('🔵 API CALL: getShopDropOrderDetail');
      logger.d('📡 URL: $url');
      logger.d('🔑 Token exists: ${ApiService.accessToken != null}');
      logger.d('🔑 Token length: ${ApiService.accessToken?.length ?? 0}');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${ApiService.accessToken}",
          "Content-Type": "application/json",
        },
      );

      logger.i('📥 Response received');
      logger.d('📊 Status code: ${response.statusCode}');
      logger.d('📦 Response body length: ${response.body.length}');
      logger.d(
        '📦 Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        logger.i('✅ API call successful');
        logger.d('📋 Response structure: ${data.keys}');
        logger.d('📋 Data keys: ${data['data']?.keys ?? 'No data field'}');
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        logger.e('❌ API call failed with status: ${response.statusCode}');
        logger.e('❌ Response body: ${response.body}');
        return {
          'success': false,
          'error':
              'Failed to load order details (Status: ${response.statusCode})',
        };
      }
    } catch (e, stackTrace) {
      logger.e('❌ Exception in getShopDropOrderDetail: $e');
      logger.e('📚 Stack trace: $stackTrace');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Add this method to your ApiService class
Future<Map<String, dynamic>> createRateCard({
  String? name,
  required double minDistanceKm,
  required double maxDistanceKm,
  required double minWeightKg,
  required double maxWeightKg,
  required double baseCharge,
  required double ratePerKm,
  required double ratePerKg,
  required double minimumCharge,
  required double carrierPercentage,
  required double shopPercentage,
  required double adminPercentage,
  required bool isActive,
  required int priority,
}) async {
  try {
    final url = Uri.parse("$baseurl/api/qdel/admin/rate/card/create/");
    
    final Map<String, dynamic> requestBody = {};
    
    // Handle nullable name
    if (name != null && name.isNotEmpty) {
      requestBody['name'] = name;
    } else {
      requestBody['name'] = null;
    }
    
    requestBody['min_distance_km'] = minDistanceKm;
    requestBody['max_distance_km'] = maxDistanceKm;
    requestBody['min_weight_kg'] = minWeightKg;
    requestBody['max_weight_kg'] = maxWeightKg;
    requestBody['base_charge'] = baseCharge;
    requestBody['rate_per_km'] = ratePerKm;
    requestBody['rate_per_kg'] = ratePerKg;
    requestBody['minimum_charge'] = minimumCharge;
    requestBody['carrier_percentage'] = carrierPercentage;
    requestBody['shop_percentage'] = shopPercentage;
    requestBody['admin_percentage'] = adminPercentage;
    requestBody['is_active'] = isActive;
    requestBody['priority'] = priority;
    
    final headers = {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };
    
    logger.i("📡 POST RATE CARD - URL: $url");
    logger.i("📦 Request Body: $requestBody");
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    
    logger.i("📥 Response Status: ${response.statusCode}");
    logger.i("📥 Response Body: ${response.body}");
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      return {
        'success': false,
        'error': 'Failed to create rate card',
        'data': null,
      };
    }
  } catch (e) {
    logger.e("🔥 RATE CARD ERROR => $e");
    return {
      'success': false,
      'error': 'Exception: $e',
      'data': null,
    };
  }
}

//   Future<Map<String, dynamic>> createRateCard({
//   String? name,
//   required double minDistanceKm,
//   required double maxDistanceKm,
//   required double minWeightKg,
//   required double maxWeightKg,
//   required double baseCharge,
//   required double ratePerKm,
//   required double ratePerKg,
//   required double minimumCharge,
//   required double carrierPercentage,
//   required double shopPercentage,
//   required double adminPercentage,
//   required bool isActive,
//   required int priority,
// }) async {
//   try {
//     final url = Uri.parse("$baseurl/api/qdel/admin/rate/card/create/");
    
//     final Map<String, dynamic> requestBody = {};
    
//     // Handle nullable name
//     if (name != null && name.isNotEmpty) {
//       requestBody['name'] = name;
//     } else {
//       requestBody['name'] = null;
//     }
    
//     requestBody['min_distance_km'] = minDistanceKm;
//     requestBody['max_distance_km'] = maxDistanceKm;
//     requestBody['min_weight_kg'] = minWeightKg;
//     requestBody['max_weight_kg'] = maxWeightKg;
//     requestBody['base_charge'] = baseCharge;
//     requestBody['rate_per_km'] = ratePerKm;
//     requestBody['rate_per_kg'] = ratePerKg;
//     requestBody['minimum_charge'] = minimumCharge;
//     requestBody['carrier_percentage'] = carrierPercentage;
//     requestBody['shop_percentage'] = shopPercentage;
//     requestBody['admin_percentage'] = adminPercentage;
//     requestBody['is_active'] = isActive;
//     requestBody['priority'] = priority;
    
//     final headers = {
//       "Authorization": "Bearer ${ApiService.accessToken}",
//       "Content-Type": "application/json",
//     };
    
//     logger.i("📡 POST RATE CARD - URL: $url");
//     logger.i("📦 Request Body: $requestBody");
    
//     final response = await http.post(
//       url,
//       headers: headers,
//       body: jsonEncode(requestBody),
//     );
    
//     logger.i("📥 Response Status: ${response.statusCode}");
//     logger.i("📥 Response Body: ${response.body}");
    
//     if (response.statusCode == 201 || response.statusCode == 200) {
//       return {
//         'success': true,
//         'data': jsonDecode(response.body),
//       };
//     } else {
//       return {
//         'success': false,
//         'error': 'Failed to create rate card',
//         'data': null,
//       };
//     }
//   } catch (e) {
//     logger.e("🔥 RATE CARD ERROR => $e");
//     return {
//       'success': false,
//       'error': 'Exception: $e',
//       'data': null,
//     };
//   }
// }
// Add these to ApiService class
static Future<void> saveShopPickupDetails(Map<String, dynamic> details) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('shop_pickup_details', jsonEncode(details));
}

static Future<Map<String, dynamic>?> getShopPickupDetails() async {
  final prefs = await SharedPreferences.getInstance();
  final String? data = prefs.getString('shop_pickup_details');
  if (data != null) {
    return jsonDecode(data);
  }
  return null;
}

static Future<void> clearShopPickupDetails() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('shop_pickup_details');
}

}
