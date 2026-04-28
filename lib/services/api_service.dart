import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://chat.alrafeeg.com';

  static Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // تسجيل الدخول
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _processResponse(response);
  }

  // إنشاء حساب جديد
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: _headers(null),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _processResponse(response);
  }

  // تحميل قائمة المحادثات
  static Future<List<Map<String, dynamic>>> getChats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/chats'),
      headers: _headers(token),
    );
    final data = _processResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // تحميل رسائل محادثة
  static Future<List<Map<String, dynamic>>> getMessages({
    required String token,
    required int userId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/$userId'),
      headers: _headers(token),
    );
    final data = _processResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // إرسال رسالة (HTTP fallback)
  static Future<bool> sendMessage({
    required String token,
    required int receiverId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/messages/send'),
      headers: _headers(token),
      body: jsonEncode({'receiver_id': receiverId, 'content': content}),
    );
    return response.statusCode == 200;
  }

  // البحث عن مستخدمين
  static Future<List<Map<String, dynamic>>> searchUsers({
    required String token,
    required String query,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/search'),
      headers: _headers(token),
      body: jsonEncode({'query': query}),
    );
    final data = _processResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // معالجة الاستجابة
  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': body['data'], 'raw': body};
      } else {
        return {
          'success': false,
          'error': body['detail'] ?? 'حدث خطأ غير متوقع',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'تعذر الاتصال بالخادم'};
    }
  }
}
