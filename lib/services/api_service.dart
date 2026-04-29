import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  /// Headers مع التوكن
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ═══════════════════════════════════════════════════
  //  AUTH
  // ═══════════════════════════════════════════════════

  /// تسجيل الدخول
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data['detail'] ?? 'خطأ في تسجيل الدخول';
    }
    return data['data'];
  }

  /// إنشاء حساب
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw data['detail'] ?? 'خطأ في التسجيل';
    }
    return data['data'];
  }

  // ═══════════════════════════════════════════════════
  //  SEARCH
  // ═══════════════════════════════════════════════════

  /// البحث عن مستخدمين
  Future<List<UserModel>> searchUsers({
    required String query,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/search'),
      headers: _headers(token),
      body: jsonEncode({'query': query}),
    );

    if (res.statusCode != 200) throw 'خطأ في البحث';
    final data = jsonDecode(res.body);
    return (data['data'] as List)
        .map((u) => UserModel.fromJson(u))
        .toList();
  }

  // ═══════════════════════════════════════════════════
  //  CHATS
  // ═══════════════════════════════════════════════════

  /// جلب قائمة المحادثات
  Future<List<ChatModel>> getChats({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/chats'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) throw 'خطأ في تحميل المحادثات';
    final data = jsonDecode(res.body);
    return (data['data'] as List)
        .map((c) => ChatModel.fromJson(c))
        .toList();
  }

  // ═══════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════

  /// جلب الرسائل مع مستخدم
  Future<List<MessageModel>> getMessages({
    required int withUserId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/messages/$withUserId'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) throw 'خطأ في تحميل الرسائل';
    final data = jsonDecode(res.body);
    return (data['data'] as List)
        .map((m) => MessageModel.fromJson(m))
        .toList();
  }

  /// إرسال رسالة عبر HTTP (fallback)
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
    required String token,
    required int myId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/messages/send'),
      headers: _headers(token),
      body: jsonEncode({'receiver_id': receiverId, 'content': content}),
    );

    if (res.statusCode != 200) throw 'خطأ في إرسال الرسالة';
    final data = jsonDecode(res.body);
    return MessageModel.fromJson(data['data']);
  }

  // ═══════════════════════════════════════════════════
  //  FCM TOKEN
  // ═══════════════════════════════════════════════════

  /// تحديث FCM Token
  Future<void> updateFcmToken({
    required String fcmToken,
    required String token,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/api/update-fcm-token'),
      headers: _headers(token),
      body: jsonEncode({'fcm_token': fcmToken}),
    );
  }
}
