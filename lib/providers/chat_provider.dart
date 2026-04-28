import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ChatProvider with ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();

  List<Chat> _chats = [];
  Map<int, List<Message>> _messages = {};
  Map<int, int> _unreadCounts = {};
  Chat? _currentChat;
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  bool _isSearching = false;
  List<User> _searchResults = [];
  bool _wsConnected = false;

  // Getters
  List<Chat> get chats => _chats;
  Map<int, List<Message>> get messages => _messages;
  Chat? get currentChat => _currentChat;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSearching => _isSearching;
  List<User> get searchResults => _searchResults;
  bool get wsConnected => _wsConnected;

  int getUnreadCount(int userId) => _unreadCounts[userId] ?? 0;

  ChatProvider() {
    _initWebSocket();
  }

  void _initWebSocket() {
    _wsService.setCallbacks(
      onMessage: _handleIncomingMessage,
      onConnectionChange: (bool connected) {
        _wsConnected = connected;
        notifyListeners();
      },
    );
  }

  void connectWebSocket(String token) {
    _wsService.connect(token);
  }

  void disconnectWebSocket() {
    _wsService.dispose();
  }

  // تحميل المحادثات
  Future<void> loadChats(String token) async {
    _isLoadingChats = true;
    notifyListeners();

    final result = await ApiService.getChats(token);
    _chats = result.map((c) => Chat.fromJson(c)).toList();
    _isLoadingChats = false;
    notifyListeners();
  }

  // تحميل رسائل محادثة
  Future<void> loadMessages({required String token, required int userId}) async {
    _isLoadingMessages = true;
    notifyListeners();

    final result = await ApiService.getMessages(token: token, userId: userId);
    _messages[userId] = result.map((m) => Message.fromJson(m)).toList();
    _isLoadingMessages = false;
    notifyListeners();
  }

  // فتح محادثة
  void openChat(Chat chat) {
    _currentChat = chat;
    _unreadCounts[chat.userId] = 0;
    notifyListeners();
  }

  // إرسال رسالة
  void sendMessage({required int receiverId, required String content, required String token}) {
    if (_currentChat == null) return;

    final tempMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: int.tryParse(token) ?? 0,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
      isTemp: true,
    );

    if (_messages[receiverId] == null) {
      _messages[receiverId] = [];
    }
    _messages[receiverId]!.add(tempMsg);

    // تحديث آخر رسالة في القائمة
    final chatIndex = _chats.indexWhere((c) => c.userId == receiverId);
    if (chatIndex >= 0) {
      _chats[chatIndex].updateFromMessage(tempMsg);
      // نقل المحادثة للأعلى
      final chat = _chats.removeAt(chatIndex);
      _chats.insert(0, chat);
    }

    // إرسال عبر WebSocket
    _wsService.sendMessage(receiverId: receiverId, content: content);

    notifyListeners();
  }

  // معالجة رسالة واردة
  void _handleIncomingMessage(Message msg) {
    final otherId = msg.senderId;
    if (_messages[otherId] == null) {
      _messages[otherId] = [];
    }

    // تجنب التكرار
    if (_messages[otherId]!.any((m) => m.id == msg.id && !m.isTemp)) return;

    // استبدال الرسالة المؤقتة
    if (_messages[otherId]!.any((m) => m.isTemp && m.content == msg.content)) {
      _messages[otherId]!.removeWhere(
        (m) => m.isTemp && m.content == msg.content,
      );
    }

    _messages[otherId]!.add(msg);

    // تحديث قائمة المحادثات
    final chatIndex = _chats.indexWhere((c) => c.userId == otherId);
    if (chatIndex >= 0) {
      _chats[chatIndex].updateFromMessage(msg);
      final chat = _chats.removeAt(chatIndex);
      _chats.insert(0, chat);
    } else {
      _chats.insert(0, Chat(
        userId: otherId,
        name: 'مستخدم $otherId',
        lastMessage: msg.content,
        timestamp: msg.timestamp,
      ));
    }

    // إذا كانت المحادثة الحالية
    if (_currentChat != null && _currentChat!.userId == otherId) {
      notifyListeners();
    } else {
      _unreadCounts[otherId] = (_unreadCounts[otherId] ?? 0) + 1;
      notifyListeners();
    }
  }

  // البحث عن مستخدمين
  Future<void> searchUsers({required String token, required String query}) async {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final result = await ApiService.searchUsers(token: token, query: query);
    _searchResults = result.map((u) => User.fromJson(u)).toList();
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
