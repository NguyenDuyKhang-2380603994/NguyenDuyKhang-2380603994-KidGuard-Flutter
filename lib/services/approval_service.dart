
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApprovalService {
  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api/Approvals';

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

  static dynamic _read(
      http.Response response,
      int expected,
      ) {
    dynamic data;

    try {
      data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } catch (_) {
      throw Exception(
        'API không trả về JSON '
            '(HTTP ${response.statusCode}). '
            'Kiểm tra Conveyor.',
      );
    }

    if (response.statusCode != expected) {
      final message = data is Map
          ? data['message'] ?? data['title']
          : null;

      throw Exception(
        message?.toString() ??
            'API lỗi ${response.statusCode}',
      );
    }

    return data;
  }

  static Future<void> requestContent({
    required String title,
    required String url,
    required int minutes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'url': url,
        'minutes': minutes,
      }),
    ).timeout(const Duration(seconds: 30));

    _read(response, 201);
  }

  static Future<List<Map<String, dynamic>>>
  mine() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mine'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as List;

    return data
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>>
  family() async {
    final response = await http.get(
      Uri.parse('$baseUrl/family'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as List;

    return data
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
  }

  static Future<void> decide({
    required int id,
    required bool approve,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/decision'),
      headers: headers,
      body: jsonEncode({
        'approve': approve,
      }),
    ).timeout(const Duration(seconds: 30));

    _read(response, 200);
  }

  static Future<Map<String, dynamic>>
  open(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$id/open'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    return Map<String, dynamic>.from(
      _read(response, 200) as Map,
    );
  }

  static Future<void> checkAccess(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/access'),
      headers: headers,
    ).timeout(const Duration(seconds: 15));

    _read(response, 200);
  }
}
