import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseurl =
      "https://holmes-built-brown-headlines.trycloudflare.com";
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
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString('accessToken');
    userType = prefs.getString('user_type');
    approvalStatus = prefs.getString('approval_status');
    phone = prefs.getString('phone');
    isFirstTime = prefs.getBool('first_time');
  }

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

 
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear(); 
    accessToken = null;
    userType = null;
    approvalStatus = null;
    phone = null;
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

      return data;
    }
    return null;
  }




  Future<List<dynamic>> getCountries() async {
    final url = Uri.parse("$baseurl/api/qdel/countries/add/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );
    logger.i("COUNTRIES STATUS :: ${response.statusCode}");
    logger.i("COUNTRIES BODY :: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load countries");
    }
  }

  Future<List<dynamic>> getStates({required int countryId}) async {
    final url = Uri.parse("$baseurl/api/qdel/states/add/?country=$countryId");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    logger.i("STATES STATUS :: ${response.statusCode}");
    logger.i("STATES BODY :: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load states");
    }
  }

  Future<List<dynamic>> getDistricts({required int stateId}) async {
    final url = Uri.parse("$baseurl/api/qdel/districts/add/?state=$stateId");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer ${ApiService.accessToken}"},
    );

    logger.i("DISTRICTS STATUS :: ${response.statusCode}");
    logger.i("DISTRICTS BODY :: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load districts");
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
    return UserModel.fromJson(jsonDecode(response.body));
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

  Future<bool> updateUserType(String userType) async {
  final url = Uri.parse("$baseurl/api/qdel/users/detail/update/self/");

  final response = await http.put(
    url,
    headers: {
      "Authorization": "Bearer ${ApiService.accessToken}",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "user_type": userType,
    }),
  );

  logger.i("USER TYPE UPDATE :: ${response.statusCode}");
  logger.i("BODY :: ${response.body}");

  return response.statusCode == 200 || response.statusCode == 204;
}


  Future<bool> registerCarrierWithDocument({
    required String phone,
    required String firstname,
    required String lastname,
    required String email,
    required String userType,
    required int? countryId,
    required int? stateId,
    required int? districtId,
    required File document,
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
      "country": countryId?.toString() ?? "",
      "state": stateId?.toString() ?? "",
      "district": districtId?.toString() ?? "",
    });

    request.files.add(
      await http.MultipartFile.fromPath("document", document.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      await ApiService.setApprovalStatus("pending");
      await ApiService.markRegistrationComplete();

      return true;
    } else {
      return false;
    }
  }
Map<String, String> _authHeaders({bool json = false}) {
  final headers = <String, String>{
    "Authorization": "Bearer ${ApiService.accessToken}",
  };

  if (json) {
    headers["Content-Type"] = "application/json";
  }

  return headers;
}

  Future<bool> uploadCarrierDocument({
  required File document,
  int? countryId,
  int? stateId,
  int? districtId,
}) async {
  final request = http.MultipartRequest(
    "POST",
    Uri.parse("$baseurl/api/carrier/request"),
  );

  request.headers.addAll(_authHeaders());

  request.files.add(
    await http.MultipartFile.fromPath("document", document.path),
  );

  request.fields["country_id"] = countryId.toString();
  request.fields["state_id"] = stateId.toString();
  request.fields["district_id"] = districtId.toString();

  final response = await request.send();
  return response.statusCode == 200 || response.statusCode == 201;
}


  static Future<void> markRegistrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    isFirstTime = false;
  }

  Future<List<UserModel>> getJoinRequests() async {
    final url = Uri.parse("$baseurl/api/qdel/admin/carriers/");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ApiService.accessToken}",
      },
    );

    logger.i("JOIN REQUESTS :: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
        decoded['data'],
      );

      return list.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load join requests");
    }
  }

  Future<bool> carrierApproval({
    required int userId,
    required bool approve,
  }) async {
    final url = Uri.parse("$baseurl/api/qdel/admin/carrier-approval/$userId/");

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
      await ApiService.loadSession();

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

  Future<bool> handleJoinRequest({
    required int requestId,
    required bool accept,
  }) async {
    final status = accept ? "approved" : "rejected";

    final url = Uri.parse("$baseurl/api/qdel/admin/carrier-approval/$status/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ApiService.accessToken}",
      },
      body: jsonEncode({"user_id": requestId}),
    );

    logger.i("URL :: $url");
    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 204;
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

  Future<List<dynamic>> statesList() async {
    Uri url = Uri.parse("$baseurl/api/qdel/states/add/");

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
      throw Exception("Failed to load State");
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

  Future<List<dynamic>> districtList() async {
    Uri url = Uri.parse("$baseurl/api/qdel/districts/add/");

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
      throw Exception("Failed to load District");
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
  Future<bool> upgradeToCarrier({
  required File document,
  int? countryId,
  int? stateId,
  int? districtId,
}) async {
  final request = http.MultipartRequest(
    "PUT",
    Uri.parse("$baseurl/api/qdel/users/detail/update/self/"),
  );

  request.headers['Authorization'] = 'Bearer $accessToken';

  request.fields.addAll({
    "user_type": "carrier",
    if (countryId != null) "country_id": countryId.toString(),
    if (stateId != null) "state_id": stateId.toString(),
    if (districtId != null) "district_id": districtId.toString(),
  });

  request.files.add(
    await http.MultipartFile.fromPath("document", document.path),
  );

  final response = await request.send();
  final body = await response.stream.bytesToString();

  logger.i("STATUS :: ${response.statusCode}");
  logger.i("BODY :: $body");

  return response.statusCode == 200;
}

}
