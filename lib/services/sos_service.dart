
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class SosService {
  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api/Sos';

  static Map<String, String> get headers {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static void check(
      http.Response response,
      int expected,
      ) {
    if (response.statusCode == expected) return;

    String message =
        'API SOS lỗi ${response.statusCode}';

    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn.');
    }

    if (response.statusCode == 403) {
      throw Exception('Tài khoản không có quyền.');
    }

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    } catch (_) {}

    throw Exception(message);
  }

  // CHILD: GỬI CẢNH BÁO
  static Future<void> send({
    required String triggerType,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/alert'),
      headers: headers,
      body: jsonEncode({
        'triggerType': triggerType,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ).timeout(const Duration(seconds: 30));

    check(response, 201);
  }

  // PARENT: LỊCH SỬ SOS
  static Future<List<Map<String, dynamic>>>
  getFamilyAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/family'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    check(response, 200);

    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as List;

    return data
        .map((e) =>
    Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // PARENT: ĐÁNH DẤU ĐÃ XỬ LÝ
  static Future<void> acknowledge(int id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/acknowledge'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    check(response, 204);
  }
}
