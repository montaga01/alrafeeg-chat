import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  String? _token;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  List<String> _emailHistory = [];

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  int get myId => _user?.id ?? 0;
  String get myName => _user?.name ?? '';
  List<String> get emailHistory => _emailHistory;

  AuthProvider() {
    _loadSession();
  }

  /// تحميل الجلسة المحفوظة
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final id = prefs.getInt('userId') ?? 0;
    final name = prefs.getString('userName') ?? '';
    final email = prefs.getString('userEmail') ?? '';

    if (_token != null && id != 0) {
      _user = UserModel(id: id, name: name, email: email);
    }

    // تحميل تاريخ البريد
    _emailHistory = prefs.getStringList('emailHistory') ?? [];

    notifyListeners();
  }

  /// حفظ الجلسة
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    _token = data['token'] as String;
    final userData = data['user'] as Map<String, dynamic>;
    _user = UserModel.fromJson(userData);

    await prefs.setString('token', _token!);
    await prefs.setInt('userId', _user!.id);
    await prefs.setString('userName', _user!.name);
    await prefs.setString('userEmail', _user!.email);
  }

  /// حفظ البريد في التاريخ
  Future<void> _saveEmailToHistory(String email) async {
    _emailHistory = _emailHistory.where((e) => e != email).toList();
    _emailHistory.insert(0, email);
    if (_emailHistory.length > 5) _emailHistory = _emailHistory.sublist(0, 5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emailHistory', _emailHistory);
  }

  /// تسجيل الدخول
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email: email, password: password);
      await _saveSession(data);
      await _saveEmailToHistory(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// إنشاء حساب
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // إنشاء الحساب
      await _api.register(name: name, email: email, password: password);
      // تسجيل الدخول مباشرة
      final data = await _api.login(email: email, password: password);
      await _saveSession(data);
      await _saveEmailToHistory(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
