# AlRafeeq Flutter Project

## تطبيق الرفيق للدردشة

تطبيق محادثات فوري يعمل على أندرويد والويب.

### المتطلبات
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK (API 21+)

### التشغيل

```bash
# تثبيت الحزم
flutter pub get

# تشغيل على أندرويد
flutter run

# بناء ملف APK
flutter build apk --release

# تشغيل على الويب
flutter run -d chrome

# بناء للويب
flutter build web
```

### هيكل المشروع

```
lib/
├── main.dart              # نقطة الدخول
├── models/                # النماذج
│   ├── user.dart
│   ├── message.dart
│   ├── chat.dart
│   └── api_response.dart
├── services/              # الخدمات
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── websocket_service.dart
├── providers/             # إدارة الحالة
│   ├── auth_provider.dart
│   └── chat_provider.dart
├── screens/               # الشاشات
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── chat_list_screen.dart
│   └── chat_room_screen.dart
└── utils/                 # أدوات مساعدة
    └── date_formatter.dart
```

### API
- Base URL: `https://chat.alrafeeg.com`
- WebSocket: `wss://chat.alrafeeg.com/ws/chat`

### المميزات
- تسجيل دخول وإنشاء حساب
- محادثات فورية عبر WebSocket
- قائمة المحادثات مع آخر رسالة
- بحث عن مستخدمين
- إشعارات
- تصميم RTL عربي كامل
- ذاكرة محلية للإيميلات
- دعم أندرويد والويب
