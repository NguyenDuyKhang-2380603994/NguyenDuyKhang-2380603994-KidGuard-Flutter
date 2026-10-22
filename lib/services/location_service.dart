
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class LocationService {
  static String get _baseUrl =>
      '${ApiConfig.baseUrl}/api/Locations';

  // JWT nhận từ Login + OTP
  static Map<String, String> get _headers {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception(
        'Phiên đăng nhập đã hết. Hãy đăng nhập lại.',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Đọc dữ liệu API và xử lý lỗi
  static dynamic _read(
      http.Response response,
      int expectedStatus,
      ) {
    dynamic payload;

    try {
      payload = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } catch (_) {
      throw Exception(
        'API trả về dữ liệu không hợp lệ '
            '(HTTP ${response.statusCode}). '
            'Kiểm tra URL Conveyor.',
      );
    }

    if (response.statusCode != expectedStatus) {
      if (response.statusCode == 401) {
        throw Exception(
          'JWT không hợp lệ. Hãy đăng nhập lại.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Tài khoản không có quyền '
              'sử dụng chức năng này.',
        );
      }

      final message = payload is Map
          ? payload['message'] ?? payload['title']
          : null;

      throw Exception(
        message?.toString() ??
            'API lỗi HTTP ${response.statusCode}',
      );
    }

    return payload;
  }

  // ==================================
  // CHILD GỬI GPS VÀO SQL SERVER
  // ==================================
  static Future<void> checkIn({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/check-in'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
      }),
    ).timeout(const Duration(seconds: 30));

    _read(response, 201);
  }

  // ==================================
  // CHILD XEM LỊCH SỬ GPS
  // ==================================
  static Future<List<Map<String, dynamic>>>
  myHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/mine'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as List;

    return data
        .map(
          (e) => Map<String, dynamic>.from(e as Map),
    )
        .toList();
  }

  // ==================================
  // PARENT XEM LỊCH SỬ VỊ TRÍ CỦA CON
  // ==================================
  static Future<List<Map<String, dynamic>>>
  familyHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/family'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as List;

    return data
        .map(
          (e) => Map<String, dynamic>.from(e as Map),
    )
        .toList();
  }
}

// Chuyển thời gian UTC sang giờ Việt Nam trên máy
String kidGuardDate(dynamic isoString) {
  final date = DateTime.tryParse(
    isoString?.toString() ?? '',
  );

  if (date == null) {
    return 'Không rõ thời gian';
  }

  final local = date.toLocal();

  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
