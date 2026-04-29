class AppConfig {
  // ⚠️ غيّر هذا لعنوان السيرفر الخاص بك
  static const String baseUrl = 'https://chat.alrafeeg.com';
  static const String wsUrl = 'wss://chat.alrafeeg.com/ws/chat';

  // ألوان التطبيق
  static const int primaryColorValue = 0xFF2F81F7;
  static const String appName = 'الرفيق';
  static const String appSubtitle = 'منصة المحادثات الفورية';

  // إعدادات
  static const int messagePageSize = 50;
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const Duration typingTimeout = Duration(seconds: 3);
  static const Duration presencePingInterval = Duration(seconds: 25);
}
