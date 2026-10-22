
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api/Admin';

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

  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 204) return;

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception('Bạn không có quyền xóa tài khoản.');
    }

    String message = 'Xóa thất bại (${response.statusCode})';

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

  static Future<dynamic> _get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn.');
    }

    if (response.statusCode == 403) {
      throw Exception('Chỉ Admin mới được truy cập.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'API Admin lỗi: ${response.statusCode}',
      );
    }

    return jsonDecode(
      utf8.decode(response.bodyBytes),
    );
  }

  static Future<Map<String, dynamic>>
  getOverview() async {
    final data = await _get('/overview');

    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<Map<String, dynamic>>>
  getUsers() async {
    final data = await _get('/users');

    return (data as List)
        .map((item) =>
    Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> assignParent({
    required int childId,
    required String parentUsername,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.childrenUrl}/$childId/assign-parent',
      ),
      headers: headers,
      body: jsonEncode({
        'username': parentUsername,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      throw Exception('Vui lòng đăng nhập lại.');
    }

    if (response.statusCode == 403) {
      throw Exception('Chỉ Admin được gán Parent.');
    }

    if (response.statusCode != 204) {
      throw Exception(
        'Gán Parent thất bại: ${response.body}',
      );
    }
  }

  // ADMIN: liên kết tài khoản Child với hồ sơ trẻ
  static Future<void> linkChild({
    required int childId,
    required String childUsername,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.childrenUrl}/$childId/link-child',
      ),
      headers: headers,
      body: jsonEncode({
        'username': childUsername.trim(),
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Hãy đăng nhập lại.');
    }

    if (response.statusCode == 403) {
      throw Exception('Chỉ Admin mới có quyền liên kết.');
    }

    String message = 'Liên kết thất bại';

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    } catch (_) {}

    throw Exception('$message (${response.statusCode})');
  }

}
