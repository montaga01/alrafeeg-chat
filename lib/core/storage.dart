import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const _tokenKey     = 'auth_token';
  static const _userIdKey    = 'user_id';
  static const _userNameKey  = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _emailHistory = 'email_history';

  static Future<void> saveSession({
    required String token,
    required int    userId,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey,     token);
    await prefs.setInt   (_userIdKey,    userId);
    await prefs.setString(_userNameKey,  name);
    await prefs.setString(_userEmailKey, email);
    await _addEmailToHistory(email);
  }

  static Future<String?> getToken()    async => (await SharedPreferences.getInstance()).getString(_tokenKey);
  static Future<int?>    getUserId()   async => (await SharedPreferences.getInstance()).getInt(_userIdKey);
  static Future<String?> getUserName() async => (await SharedPreferences.getInstance()).getString(_userNameKey);

  static Future<void> clear() async {
    final prefs   = await SharedPreferences.getInstance();
    final history = prefs.getString(_emailHistory);
    await prefs.clear();
    if (history != null) await prefs.setString(_emailHistory, history);
  }

  static Future<void> _addEmailToHistory(String email) async {
    if (email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_emailHistory);
    final List<String> list = raw != null ? List<String>.from(jsonDecode(raw)) : [];
    list.remove(email);
    list.insert(0, email);
    if (list.length > 5) list.removeLast();
    await prefs.setString(_emailHistory, jsonEncode(list));
  }

  static Future<List<String>> getEmailHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_emailHistory);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }
}
