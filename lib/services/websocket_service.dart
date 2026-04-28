import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';

typedef MessageCallback = void Function(Message message);

class WebSocketService {
  static const String wsBaseUrl = 'wss://chat.alrafeeg.com/ws/chat';

  WebSocketChannel? _channel;
  String? _token;
  MessageCallback? onMessageReceived;
  Function? onConnectionChanged;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  bool get isConnected => _isConnected;

  void setCallbacks({
    MessageCallback? onMessage,
    Function? onConnectionChange,
  }) {
    onMessageReceived = onMessage;
    onConnectionChanged = onConnectionChange;
  }

  void connect(String token) {
    _token = token;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_token == null || _token!.isEmpty) return;

    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse('$wsBaseUrl/$_token'));

      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          _isConnected = true;
          onConnectionChanged?.call(true);

          try {
            final parsed = jsonDecode(data);
            if (parsed['status'] == 'sent' || parsed['error'] != null) return;

            final message = Message.fromJson(parsed);
            onMessageReceived?.call(message);
          } catch (e) {
            // تجاهل الرسائل غير الصالحة
          }
        },
        onDone: () {
          _isConnected = false;
          onConnectionChanged?.call(false);
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          onConnectionChanged?.call(false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    Future.delayed(
      Duration(seconds: _reconnectAttempts * 2),
      () => _doConnect(),
    );
  }

  void sendMessage({required int receiverId, required String content}) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({
        'receiver_id': receiverId,
        'content': content,
      }));
    }
  }

  void disconnect() {
    _reconnectAttempts = _maxReconnectAttempts; // منع إعادة الاتصال
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _token = null;
  }

  void dispose() {
    disconnect();
    onMessageReceived = null;
    onConnectionChanged = null;
  }
}
