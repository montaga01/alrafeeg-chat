// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'package:flutter/foundation.dart'; // لـ kIsWeb

// ─── معالج الخلفية — يجب أن يكون خارج أي class ───
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'alrafeeg_channel',
    'إشعارات الرفيق',
    description: 'رسائل ومحادثات جديدة',
    importance: Importance.high,
    playSound: true,
  );

  // ─── استدعي هذه مرة واحدة في main() ───
  Future<void> init() async {
    // 1. تسجيل معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. طلب الإذن
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 3. إعداد الإشعارات المحلية
    await _initLocal();

    // 4. الاستماع للإشعارات
    _listenForeground();
    _listenOnOpen();

    // 5. حفظ وإرسال التوكن للسيرفر
    await _registerToken();
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ─── إشعار وهو مفتوح (Foreground) ───
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _localNotif.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
          ),
        ),
        payload: jsonEncode(msg.data),
      );
    });
  }

  // ─── المستخدم يضغط على الإشعار ───
  void _listenOnOpen() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleData);
  }

  void _onTap(NotificationResponse res) {
    if (res.payload == null) return;
    _handleData(null, extra: jsonDecode(res.payload!));
  }

  // ─── routing حسب نوع الإشعار ───
  void _handleData(RemoteMessage? msg, {Map<String, dynamic>? extra}) {
    final data = msg?.data ?? extra ?? {};
    final type = data['type'] as String? ?? '';

    // أمثلة — عدّل حسب شاشاتك:
    // if (type == 'message')  → افتح شاشة المحادثة
    // if (type == 'friend')   → افتح طلبات الصداقة
    // print للتطوير:
    print('📩 إشعار: type=$type | data=$data');
  }

  // ─── تسجيل التوكن مع السيرفر ───
  Future<void> _registerToken() async {
  _fcm.onTokenRefresh.listen(_sendToken);

  // ✅ vapidKey للويب فقط، الأندرويد بدونها
  final token = await _fcm.getToken(
      vapidKey: kIsWeb 
        ? 'BGCmBOj4n4W3yDwjmX7Kq1fxf9SjJpFj3yKrPs7ko1RlC_E1kUUbktxEEUTrv6GoAAF01h4V3fu9tqwgYPf6Z48'
        : null,
    );
    if (token != null) await _sendToken(token);
  }

  Future<void> _sendToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token'); // توكن تسجيل الدخول عندك
      if (authToken == null) return; // المستخدم ما سجل بعد

      await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (_) {
      // سيُعاد المحاولة في المرة القادمة
    }
  }

  // ─── للاختبار السريع من أي شاشة ───
  Future<void> showTestNotification({
    String title = '🔔 الرفيق',
    String body = 'هذا إشعار تجريبي!',
  }) async {
    await _localNotif.show(
      0, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getToken() => _fcm.getToken();

  // أضف هذه الدالة — تُستدعى بعد تسجيل الدخول مباشرة
  Future<void> retryRegisterToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _sendToken(token);
  }
}
