import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseurl =
      "https://mounts-gravity-discharge-texts.trycloudflare.com";
  Logger logger = Logger();

  static bool? isFirstTime;

  static Future<void> setFirstTime(bool value) async {
    isFirstTime = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', value);
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
    userType = prefs.getString('user_type');
    isFirstTime = prefs.getBool('first_time');
  }

  static String? accessToken;

  static Future<void> setToken(String token) async {
    accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
  }

  static Future<void> logout() async {
    accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static String? userType;

  static Future<void> setUserType(String type) async {
    userType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type);
  }

  static Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
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

  Future otp({required String phone, required String otp}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/verify/otp/");

    var headers = {"Content-Type": "application/json"};

    var body = jsonEncode({"phone": phone, "otp": otp});

    final response = await http.post(url, headers: headers, body: body);

    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      ApiService.setToken(data['access']);
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
    Uri url = Uri.parse("$baseurl/api/qdel/register/");

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };

    var body = jsonEncode({
      "phone": phone,
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "user_type": userType,
      "country": countryId,
      "state": stateId,
      "district": districtId,
    });

    final response = await http.post(url, headers: headers, body: body);

    logger.i("STATUS :: ${response.statusCode}");
    logger.i("BODY :: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
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

  Future<bool> addCountry({required String name}) async {
    Uri url = Uri.parse("$baseurl/api/qdel/countries/add/");
    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiService.accessToken}",
    };
    var body = jsonEncode({"name": name});
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
}) async {
  Uri url = Uri.parse(
    "$baseurl/api/qdel/countries/update/$countryId/"
  );

  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${ApiService.accessToken}",
  };

  var body = jsonEncode({
    "name": name,
  });
  logger.i("UPDATE COUNTRY URL :: $url");
  logger.i("TOKEN :: ${ApiService.accessToken}");
  logger.i("BODY SENT :: $body");
  final response = await http.put(
    url,
    headers: headers,
    body: body,
  );
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
  Uri url = Uri.parse(
    "$baseurl/api/qdel/states/update/$stateId/"
  );
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${ApiService.accessToken}",
  };
  var body = jsonEncode({
    "name": name,
    "country": countryId,
  });
  logger.i("UPDATE STATE URL :: $url");
  logger.i("TOKEN :: ${ApiService.accessToken}");
  logger.i("BODY SENT :: $body");
  final response = await http.put(
    url,
    headers: headers,
    body: body,
  );
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
  Uri url = Uri.parse(
    "$baseurl/api/qdel/districts/update/$districtId/"
  );
  var headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${ApiService.accessToken}",
  };
  var body = jsonEncode({
    "name": name,
    "state": stateId,
  });
  logger.i("UPDATE DISTRICT URL :: $url");
  logger.i("TOKEN :: ${ApiService.accessToken}");
  logger.i("BODY SENT :: $body");
  final response = await http.put(
    url,
    headers: headers,
    body: body,
  );
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
}
