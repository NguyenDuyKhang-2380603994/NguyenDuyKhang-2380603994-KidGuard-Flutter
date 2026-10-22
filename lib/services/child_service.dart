
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ChildService {
  static String get baseUrl => ApiConfig.childrenUrl;

  // LẤY JWT TOKEN SAU KHI ĐĂNG NHẬP OTP
  static Map<String, String> get authHeaders {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception(
        'Bạn chưa đăng nhập hoặc phiên đăng nhập đã hết.',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // XỬ LÝ LỖI API
  static void checkResponse(
      http.Response response,
      int expectedStatus,
      ) {
    if (response.statusCode == expectedStatus) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Phiên đăng nhập không hợp lệ. Hãy đăng nhập lại.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Tài khoản của bạn không có quyền thực hiện chức năng này.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Không tìm thấy hồ sơ hoặc bạn không có quyền truy cập.',
      );
    }

    String message = 'Lỗi API: ${response.statusCode}';

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is Map) {
        message = (data['message'] ??
            data['title'] ??
            message)
            .toString();
      }
    } catch (_) {
      // Giữ thông báo lỗi theo HTTP status.
    }

    throw Exception(message);
  }

  static Future<void> createChildAccount({
    required String name,
    required int age,
    required String device,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: authHeaders,
      body: jsonEncode({
        'name': name,
        'age': age,
        'device': device,
        'username': username,
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) return;

    String message =
        'Không thể tạo Child (${response.statusCode})';

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (data is Map) {
        message = data['message']?.toString() ?? message;

        if (data['errors'] is List) {
          final errors = (data['errors'] as List)
              .map((e) => e.toString())
              .join('\n');

          message = '$message\n$errors';
        }
      }
    } catch (_) {}

    throw Exception(message);
  }

  // ====================================
  // READ - ADMIN VÀ PARENT
  // ADMIN: xem tất cả
  // PARENT: chỉ xem hồ sơ của mình
  // CHILD: bị chặn 403
  // ====================================
  static Future<List<dynamic>> getChildren() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 30));

    checkResponse(response, 200);

    return jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as List<dynamic>;
  }

  // ====================================
  // READ - CHILD
  // Child chỉ xem hồ sơ của chính mình
  // ====================================
  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 30));

    checkResponse(response, 200);

    return jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;
  }

  // ====================================
  // CREATE - ADMIN VÀ PARENT
  // PARENT: ParentId do backend tự gán
  // ADMIN: chọn ParentUsername
  // ====================================
  static Future<void> addChild({
    required String name,
    required int age,
    required String device,
    String? parentUsername,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'age': age,
      'device': device,
    };

    if (parentUsername != null &&
        parentUsername.trim().isNotEmpty) {
      body['parentUsername'] = parentUsername.trim();
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: authHeaders,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    checkResponse(response, 201);
  }

  // ====================================
  // UPDATE - ADMIN VÀ PARENT
  // Chỉ sửa hồ sơ được phép quản lý
  // ====================================
  static Future<void> updateChild({
    required int id,
    required String name,
    required int age,
    required String device,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: authHeaders,
      body: jsonEncode({
        'id': id,
        'name': name,
        'age': age,
        'device': device,
      }),
    ).timeout(const Duration(seconds: 30));

    checkResponse(response, 204);
  }

  // ====================================
  // DELETE - ADMIN VÀ PARENT
  // CHILD KHÔNG ĐƯỢC XÓA
  // ====================================
  static Future<void> deleteChild(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: authHeaders,
    ).timeout(const Duration(seconds: 30));

    checkResponse(response, 204);
  }
}
