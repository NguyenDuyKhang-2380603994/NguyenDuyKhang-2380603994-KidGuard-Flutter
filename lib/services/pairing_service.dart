
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class PairingService {
  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api/Pairings';

  static Map<String, String> get headers {
    final token = AuthService.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Hãy đăng nhập lại KidGuard.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _read(
      http.Response response,
      int expectedCode,
      ) {
    dynamic data;

    try {
      data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } catch (_) {
      throw Exception(
        'API không trả về JSON. '
            'Kiểm tra kết nối Conveyor '
            '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập không hợp lệ.');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Tài khoản không có quyền thực hiện.',
      );
    }

    if (response.statusCode != expectedCode) {
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

  // PARENT: TẠO QR
  static Future<Map<String, dynamic>> create(
      int childId,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: headers,
      body: jsonEncode({
        'childId': childId,
      }),
    ).timeout(const Duration(seconds: 30));

    return Map<String, dynamic>.from(
      _read(response, 200) as Map,
    );
  }

  // PARENT: XEM TRẠNG THÁI GHÉP THIẾT BỊ
  static Future<List<Map<String, dynamic>>>
  family() async {
    final response = await http.get(
      Uri.parse('$baseUrl/family'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as List;

    return data
        .map(
          (e) => Map<String, dynamic>.from(e as Map),
    )
        .toList();
  }

  // ID ngẫu nhiên riêng cho bản cài đặt ứng dụng.
  // Không phải IMEI hay ID phần cứng.
  static Future<String> getInstallationId() async {
    final prefs = SharedPreferencesAsync();

    var id = await prefs.getString(
      'kidguard_installation_id',
    );

    if (id != null && id.isNotEmpty) {
      return id;
    }

    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    id = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    await prefs.setString(
      'kidguard_installation_id',
      id,
    );

    return id;
  }

  // CHILD: QUÉT VÀ XÁC NHẬN QR
  static Future<String> redeem({
    required String qrPayload,
    required String deviceName,
  }) async {
    final installationId =
    await getInstallationId();

    final response = await http.post(
      Uri.parse('$baseUrl/redeem'),
      headers: headers,
      body: jsonEncode({
        'qrPayload': qrPayload,
        'deviceName': deviceName.trim(),
        'installationId': installationId,
      }),
    ).timeout(const Duration(seconds: 30));

    final data = _read(response, 200) as Map;

    return data['message']?.toString() ??
        'Liên kết thành công!';
  }
}
