
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthService {
  // Lưu token tạm trong phiên ứng dụng
  static String? accessToken;


  static String? username;
  static String? fullName;
  static String? userRole;
  static const headers = {
    'Content-Type': 'application/json',
  };

  // Đọc kết quả JSON
  static Map<String, dynamic> _readData(
      http.Response response,
      ) {
    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Phản hồi API không hợp lệ');
  }

  // BƯỚC 1: LOGIN => GỬI OTP
  static Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 45));

    final data = _readData(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ??
            'Đăng nhập thất bại (${response.statusCode})',
      );
    }

    final challengeId =
    data['challengeId']?.toString();

    if (challengeId == null || challengeId.isEmpty) {
      throw Exception('API không trả về Challenge ID');
    }

    return challengeId;
  }

  // BƯỚC 2: XÁC THỰC OTP => NHẬN JWT VÀ ROLE
  static Future<String> verifyOtp({
    required String challengeId,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.verifyOtpUrl),
      headers: headers,
      body: jsonEncode({
        'challengeId': challengeId,
        'otp': otp,
      }),
    ).timeout(const Duration(seconds: 30));

    final data = _readData(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ??
            'Xác thực OTP thất bại',
      );
    }

    final token = data['token']?.toString();
    final role = data['role']?.toString();

    if (token == null ||
        token.isEmpty ||
        role == null ||
        role.isEmpty) {
      throw Exception(
        'API không trả về JWT Token hoặc Role',
      );
    }


    accessToken = token;

// Lấy thông tin người dùng từ API
    username = data['username']?.toString();
    fullName = data['fullName']?.toString();
    userRole = role;

    return role;

  }

  // ĐĂNG KÝ TÀI KHOẢN KIDGUARD
  static Future<String> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String accountType,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registerUrl),
      headers: headers,
      body: jsonEncode({
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
        'accountType': accountType,
      }),
    ).timeout(const Duration(seconds: 30));

    final data = _readData(response);

    if (response.statusCode == 200) {
      return data['message']?.toString() ??
          'Đăng ký thành công!';
    }

    final errors = data['errors'];

    if (errors is List && errors.isNotEmpty) {
      throw Exception(
        errors.map((e) => e.toString()).join('\n'),
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Đăng ký thất bại (${response.statusCode})',
    );
  }

  // Đăng xuất

  static void logout() {
    accessToken = null;
    username = null;
    fullName = null;
    userRole = null;
  }

}
