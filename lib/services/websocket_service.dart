import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../models/message.dart';

/// ══════════════════════════════════════════════════════════════
///  WebSocketService — اتصال مركزي واحد لكل التطبيق
///
///  • كل رسالة تصل تُبثّ في [messages] (تشمل أي محادثة)
///  • [incomingChats] يُبثّ تحديثات قائمة المحادثات (معرّف المُرسِل)
///  • التطبيق يخزّن الرسائل محلياً، السيرفر يدفعها push
/// ══════════════════════════════════════════════════════════════
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  bool _isConnected = false;

  // ── Streams العامة ─────────────────────────────────────────────
  final _msgCtrl  = StreamController<Message>.broadcast();
  final _chatCtrl = StreamController<int>.broadcast();   // sender_id للمحادثة الجديدة

  Stream<Message> get messages     => _msgCtrl.stream;
  Stream<int>     get incomingChats => _chatCtrl.stream;
  bool get isConnected              => _isConnected;

  // ── الاتصال ────────────────────────────────────────────────────
  void connect(String token) {
    if (_isConnected) return;
    final uri = Uri.parse('${AppConstants.wsUrl}/$token');
    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    _channel!.stream.listen(
      (data) {
        final json = jsonDecode(data as String);
        // رسائل تأكيد الإرسال — نتجاهلها
        if (json['status'] == 'sent') return;
        if (json['error'] != null) return;

        final msg = Message.fromJson(json);
        _msgCtrl.add(msg);

        // إبلاغ HomeScreen بوجود محادثة جديدة/محدّثة
        _chatCtrl.add(msg.senderId);
      },
      onError: (_) => _isConnected = false,
      onDone:  ()  => _isConnected = false,
    );

    // ping كل 25 ثانية لإبقاء الاتصال حياً
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try { _channel?.sink.add('ping'); } catch (_) {}
    });
  }

  // ── إرسال رسالة ────────────────────────────────────────────────
  void sendMessage({required int receiverId, required String content}) {
    _channel?.sink.add(jsonEncode({
      'receiver_id': receiverId,
      'content':     content,
    }));
  }

  // ── قطع الاتصال ────────────────────────────────────────────────
  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel     = null;
    _isConnected = false;
  }
}
