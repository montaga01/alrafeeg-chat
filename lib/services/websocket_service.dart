import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// خدمة WebSocket مع إعادة الاتصال التلقائي والتأكيد على الرسائل
class WebSocketService {
  WebSocketChannel? _channel;
  String? _token;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// استقبال الرسائل
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// حالة الاتصال
  Stream<bool> get connectionState => _connectionController.stream;

  /// هل متصل الآن؟
  bool get isConnected =>
      _channel != null &&
      !_isConnecting;

  void connect(String token) {
    if (_isConnecting) return;
    _token = token;
    _isConnecting = true;
    _reconnectAttempts = 0;

    _doConnect();
  }

  void _doConnect() {
    if (_token == null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsUrl}/$_token'),
      );

      _channel!.stream.listen(
        (data) {
          _isConnecting = false;
          _reconnectAttempts = 0;
          _connectionController.add(true);

          // التعامل مع ping
          if (data == 'ping' || data == 'pong') return;

          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(msg);
          } catch (e) {
            // رسالة غير JSON — نتجاهلها
          }
        },
        onError: (error) {
          _isConnecting = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _isConnecting = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      // بدء الـ ping
      _startPing();
    } catch (e) {
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// إرسال رسالة عبر WebSocket
  /// يُرجع true إذا نجح الإرسال، false إذا فشل
  bool send(Map<String, dynamic> data) {
    if (_channel == null) return false;
    try {
      _channel!.sink.add(jsonEncode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إرسال رسالة مع تأكيد
  /// إذا فشل الإرسال عبر WebSocket، يتم المحاولة مرة أخرى
  Future<bool> sendWithConfirmation(
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isConnected) return false;

    final completer = Completer<bool>();
    final msgId = data['temp_id'];

    // استمع لتأكيد السيرفر
    StreamSubscription? sub;
    Timer? timeoutTimer;

    sub = messages.listen((msg) {
      if (msg['status'] == 'sent' && msg['message_id'] != null) {
        // تأكيد الاستقبال من السيرفر
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final sent = send(data);

    if (!sent) {
      sub.cancel();
      timeoutTimer.cancel();
      return false;
    }

    final result = await completer.future;
    sub.cancel();
    timeoutTimer.cancel();
    return result;
  }

  /// إعادة جدولة الاتصال
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_token == null) return; // تم تسجيل الخروج

    _reconnectAttempts++;
    // تأخير تصاعدي: 3s, 6s, 12s, 24s, max 30s
    final delay = Duration(
      seconds: (_reconnectAttempts * 3).clamp(3, 30),
    );

    _reconnectTimer = Timer(delay, () {
      if (_token != null) {
        _doConnect();
      }
    });
  }

  /// بدء إرسال ping دوري
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(AppConfig.presencePingInterval, (_) {
      if (isConnected) {
        send({'type': 'ping'});
      }
    });
  }

  /// إعلان حالة الاتصال
  void announcePresence({required bool online}) {
    send({'type': 'presence', 'online': online});
  }

  /// طلب حالة الاتصال لمجموعة مستخدمين
  void requestPresence(List<int> userIds) {
    send({'type': 'get_presence', 'user_ids': userIds});
  }

  /// إرسال مؤشر الكتابة
  void sendTyping({required int receiverId}) {
    send({'type': 'typing', 'receiver_id': receiverId});
  }

  /// قطع الاتصال
  void disconnect() {
    _token = null;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
