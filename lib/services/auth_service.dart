import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _savedEmailsKey = 'savedEmails';

  String? _token;
  int? _userId;
  String? _userName;
  String? _userEmail;

  String? get token => _token;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _token != null;

  // تحميل البيانات المحفوظة
  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getInt(_userIdKey);
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
  }

  // تسجيل الدخول
  Future<({bool success, String? error, User? user})> login({
    required String email,
    required String password,
  }) async {
    final result = await ApiService.login(email: email, password: password);

    if (result['success'] == true) {
      final data = result['data'];
      _token = data['token'];
      _userId = data['user']['id'];
      _userName = data['user']['name'];
      _userEmail = data['user']['email'];

      final user = User.fromJson(data['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setInt(_userIdKey, _userId!);
      await prefs.setString(_userNameKey, _userName!);
      await prefs.setString(_userEmailKey, _userEmail ?? email);

      // حفظ الإيميل
      await saveEmail(email);

      return (success: true, error: null, user: user);
    } else {
      return (success: false, error: result['error'], user: null);
    }
  }

  // إنشاء حساب
  Future<({bool success, String? error})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await ApiService.register(
      name: name,
      email: email,
      password: password,
    );

    if (result['success'] == true) {
      return (success: true, error: null);
    } else {
      return (success: false, error: result['error']);
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
  }

  // حفظ الإيميلات
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_savedEmailsKey) ?? [];
    emails.remove(email);
    emails.insert(0, email);
    if (emails.length > 5) emails.removeRange(5, emails.length);
    await prefs.setStringList(_savedEmailsKey, emails);
  }

  // استرجاع الإيميلات المحفوظة
  Future<List<String>> getSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedEmailsKey) ?? [];
  }

  // حذف إيميل محفوظ
  Future<void> removeEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_savedEmailsKey) ?? [];
    emails.remove(email);
    await prefs.setStringList(_savedEmailsKey, emails);
  }
}
