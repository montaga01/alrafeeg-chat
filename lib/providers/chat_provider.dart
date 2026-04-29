import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final WebSocketService _ws = WebSocketService();
  final StorageService _storage = StorageService();

  List<ChatModel> _chats = [];
  Map<int, List<MessageModel>> _messages = {};
  Map<int, bool> _presence = {}; // userId -> isOnline
  Map<int, DateTime?> _lastSeen = {}; // userId -> lastSeen
  Set<int> _unreadChats = {};

  ChatModel? _currentChat;
  bool _isWsConnected = false;
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  Map<int, bool> _typingUsers = {}; // userId -> isTyping
  String? _token;
  int _myId = 0;

  // للتحكم بمؤشر الكتابة
  Timer? _typingTimer;
  DateTime? _lastTypingSent;

  // Retry queue for failed messages
  final List<MessageModel> _failedMessages = [];

  List<ChatModel> get chats => _chats;
  ChatModel? get currentChat => _currentChat;
  bool get isWsConnected => _isWsConnected;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  List<MessageModel> get failedMessages => _failedMessages;
  WebSocketService get ws => _ws;

  List<MessageModel> messagesForChat(int userId) => _messages[userId] ?? [];

  bool isUserOnline(int userId) => _presence[userId] ?? false;
  DateTime? lastSeenFor(int userId) => _lastSeen[userId];
  bool isUserTyping(int userId) => _typingUsers[userId] ?? false;
  bool hasUnread(int userId) => _unreadChats.contains(userId);

  void init({required String token, required int myId}) {
    _token = token;
    _myId = myId;

    // الاستماع لحالة اتصال WebSocket
    _ws.connectionState.listen((connected) {
      _isWsConnected = connected;
      if (connected) {
        // أعلن حالة الاتصال
        _ws.announcePresence(online: true);
        // اطلب حالة الاتصال للمحادثات
        _requestPresenceForChats();
      }
      notifyListeners();
    });

    // الاستماع للرسائل الواردة
    _ws.messages.listen(_handleWsMessage);

    // الاتصال بـ WebSocket
    _ws.connect(token);

    // تحميل المحادثات
    loadChats();
  }

  // ═══════════════════════════════════════════════════
  //  CHATS
  // ═══════════════════════════════════════════════════

  Future<void> loadChats() async {
    _isLoadingChats = true;
    notifyListeners();

    try {
      // أولاً حاول نحمّل من التخزين المحلي
      final localMessages = await _storage.getAllLastMessages(_myId);
      final localMetas = await _storage.getChatMetas();

      if (localMessages.isNotEmpty && _token != null) {
        // حوّل الرسائل المحلية لقائمة محادثات مؤقتة
        _chats = _buildChatsFromLocal(localMessages, localMetas);
        notifyListeners();
      }

      // حمّل من السيرفر
      if (_token != null) {
        final serverChats = await _api.getChats(token: _token!);
        _chats = serverChats;

        // حدّث التخزين المحلي
        for (final chat in serverChats) {
          await _storage.saveChatMeta({
            'user_id': chat.userId,
            'name': chat.name,
            'last_message': chat.lastMessage,
            'last_message_time': chat.lastMessageTime?.toIso8601String(),
            'unread_count': chat.unreadCount,
          });
        }
      }
    } catch (e) {
      // في حالة خطأ السيرفر، نستخدم البيانات المحلية
      if (_chats.isEmpty) {
        final localMessages = await _storage.getAllLastMessages(_myId);
        final localMetas = await _storage.getChatMetas();
        _chats = _buildChatsFromLocal(localMessages, localMetas);
      }
    }

    _isLoadingChats = false;
    notifyListeners();
  }

  List<ChatModel> _buildChatsFromLocal(
    List<Map<String, dynamic>> localMessages,
    List<Map<String, dynamic>> localMetas,
  ) {
    final metaMap = <int, Map<String, dynamic>>{};
    for (final m in localMetas) {
      metaMap[m['user_id'] as int] = m;
    }

    return localMessages.map((row) {
      final peerId = (row['sender_id'] as int) == _myId
          ? row['receiver_id'] as int
          : row['sender_id'] as int;
      final meta = metaMap[peerId];
      return ChatModel(
        userId: peerId,
        name: meta?['name'] as String? ?? 'مستخدم',
        lastMessage: row['content'] as String?,
        lastMessageTime: row['timestamp'] != null
            ? DateTime.tryParse(row['timestamp'].toString())
            : null,
        unreadCount: meta?['unread_count'] as int? ?? 0,
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════

  Future<void> loadMessages(int withUserId) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      // حمّل من التخزين المحلي أولاً
      final localMsgs = await _storage.getMessages(_myId, withUserId);
      if (localMsgs.isNotEmpty) {
        _messages[withUserId] = localMsgs;
        notifyListeners();
      }

      // حمّل التحديثات من السيرفر
      if (_token != null) {
        final serverMsgs =
            await _api.getMessages(withUserId: withUserId, token: _token!);

        // دمج الرسائل: أضف فقط الرسائل الجديدة اللي ما هي محفوظة
        final existingIds = (localMsgs).map((m) => m.id).toSet();
        final newMsgs =
            serverMsgs.where((m) => !existingIds.contains(m.id)).toList();

        if (newMsgs.isNotEmpty) {
          _messages[withUserId] = [...localMsgs, ...newMsgs];
          // حفظ الرسائل الجديدة محلياً
          await _storage.saveMessages(newMsgs);
        } else {
          _messages[withUserId] = serverMsgs;
          await _storage.saveMessages(serverMsgs);
        }
      }
    } catch (e) {
      // استخدم البيانات المحلية إذا فشل السيرفر
      if (_messages[withUserId] == null || _messages[withUserId]!.isEmpty) {
        final localMsgs = await _storage.getMessages(_myId, withUserId);
        _messages[withUserId] = localMsgs;
      }
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  //  SEND MESSAGE - مع إصلاح مشكلة سقوط الرسائل
  // ═══════════════════════════════════════════════════

  Future<void> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    final now = DateTime.now();
    final tempId = -now.millisecondsSinceEpoch; // ID مؤقت سالب

    final tempMsg = MessageModel(
      id: tempId,
      senderId: _myId,
      receiverId: receiverId,
      content: content,
      timestamp: now,
      status: MessageStatus.sending,
    );

    // أضف الرسالة فوراً للقائمة
    if (_messages[receiverId] == null) _messages[receiverId] = [];
    _messages[receiverId]!.add(tempMsg);
    _updateChatWithMessage(receiverId, tempMsg);
    notifyListeners();

    // حفظ محلياً
    await _storage.saveMessage(tempMsg);

    // حاول الإرسال عبر WebSocket
    bool sent = false;
    if (_ws.isConnected) {
      sent = _ws.send({
        'receiver_id': receiverId,
        'content': content,
        'temp_id': tempId,
      });
    }

    if (!sent && _token != null) {
      // Fallback: أرسل عبر HTTP
      try {
        final serverMsg = await _api.sendMessage(
          receiverId: receiverId,
          content: content,
          token: _token!,
          myId: _myId,
        );

        // حدّث الرسالة المؤقتة بالرسالة الحقيقية
        final idx = _messages[receiverId]?.indexWhere((m) => m.id == tempId);
        if (idx != null && idx >= 0) {
          _messages[receiverId]![idx] = serverMsg;
          await _storage.saveMessage(serverMsg);
          // احذف الرسالة المؤقتة
          // (saveMessage with replace will handle it)
        }

        notifyListeners();
      } catch (e) {
        // تعليم الرسالة كفاشلة
        _markMessageFailed(receiverId, tempId);
      }
    } else if (sent) {
      // حدّث الحالة لـ sent بعد فترة قصيرة
      Future.delayed(const Duration(seconds: 2), () {
        _updateMessageStatus(receiverId, tempId, MessageStatus.sent);
      });
    }
  }

  /// إعادة إرسال رسالة فاشلة
  Future<void> retryMessage(int receiverId, int messageId) async {
    final msgs = _messages[receiverId];
    if (msgs == null) return;

    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;

    final msg = msgs[idx];
    // غيّر الحالة لـ sending
    msgs[idx] = msg.copyWith(status: MessageStatus.sending);
    notifyListeners();

    // حاول الإرسال مرة أخرى
    if (_token != null) {
      try {
        final serverMsg = await _api.sendMessage(
          receiverId: receiverId,
          content: msg.content,
          token: _token!,
          myId: _myId,
        );
        msgs[idx] = serverMsg;
        await _storage.saveMessage(serverMsg);
        notifyListeners();
      } catch (e) {
        msgs[idx] = msg.copyWith(status: MessageStatus.failed);
        notifyListeners();
      }
    }
  }

  void _markMessageFailed(int receiverId, int tempId) {
    final msgs = _messages[receiverId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.id == tempId);
    if (idx >= 0) {
      msgs[idx] = msgs[idx].copyWith(status: MessageStatus.failed);
      notifyListeners();
    }
  }

  void _updateMessageStatus(
      int receiverId, int msgId, MessageStatus status) {
    final msgs = _messages[receiverId];
    if (msgs == null) return;
    final idx = msgs.indexWhere((m) => m.id == msgId);
    if (idx >= 0) {
      msgs[idx] = msgs[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  //  WEBSOCKET MESSAGE HANDLER
  // ═══════════════════════════════════════════════════

  void _handleWsMessage(Map<String, dynamic> msg) {
    // ── Presence update ──
    if (msg['type'] == 'presence') {
      final uid = msg['user_id'] as int?;
      if (uid != null && uid != _myId) {
        _presence[uid] = msg['online'] as bool? ?? false;
        if (msg['last_seen'] != null) {
          _lastSeen[uid] = DateTime.tryParse(msg['last_seen'].toString());
        }
        notifyListeners();
      }
      return;
    }

    // ── Online users batch ──
    if (msg['type'] == 'online_users') {
      final ids = (msg['user_ids'] as List?)?.cast<int>() ?? [];
      for (final uid in ids) {
        if (uid != _myId) _presence[uid] = true;
      }
      notifyListeners();
      return;
    }

    // ── Typing indicator ──
    if (msg['type'] == 'typing') {
      final from = msg['sender_id'] as int? ?? msg['user_id'] as int?;
      if (from != null && from != _myId) {
        _typingUsers[from] = true;
        notifyListeners();
        // إخفاء بعد 3 ثوانٍ
        Future.delayed(const Duration(seconds: 3), () {
          _typingUsers[from] = false;
          notifyListeners();
        });
      }
      return;
    }

    // ── Sent confirmation ──
    if (msg['status'] == 'sent' && msg['message_id'] != null) {
      // السيرفر أكد الاستقبال — لا نحتاج نعمل شي حالياً
      return;
    }

    // ── Error ──
    if (msg['error'] != null) return;

    // ── رسالة جديدة ──
    final senderId = msg['sender_id'] as int?;
    final receiverId = msg['receiver_id'] as int?;
    if (senderId == null || receiverId == null) return;

    final newMsg = MessageModel.fromJson(msg);
    final peerId = senderId == _myId ? receiverId : senderId;

    // أضف للقائمة
    if (_messages[peerId] == null) _messages[peerId] = [];

    // تحقق من عدم التكرار
    final exists = _messages[peerId]!.any((m) => m.id == newMsg.id && newMsg.id > 0);
    if (!exists) {
      _messages[peerId]!.add(newMsg);
      // حفظ محلياً
      _storage.saveMessage(newMsg);
    }

    // إخفاء مؤشر الكتابة
    _typingUsers[peerId] = false;

    // تحديث قائمة المحادثات
    _updateChatWithMessage(peerId, newMsg);

    // إشعار غير مقروء
    if (senderId != _myId && _currentChat?.userId != peerId) {
      _unreadChats.add(peerId);
    }

    // حدّث حالة الاتصال للمرسل
    if (senderId != _myId) {
      _presence[senderId] = true;
    }

    notifyListeners();
  }

  void _updateChatWithMessage(int peerId, MessageModel msg) {
    final existingIdx = _chats.indexWhere((c) => c.userId == peerId);
    if (existingIdx >= 0) {
      final chat = _chats[existingIdx];
      _chats[existingIdx] = chat.copyWith(
        lastMessage: msg.content,
        lastMessageTime: msg.timestamp,
      );
      // انقل المحادثة للأعلى
      final updated = _chats.removeAt(existingIdx);
      _chats.insert(0, updated);
    } else {
      _chats.insert(
        0,
        ChatModel(
          userId: peerId,
          name: '...', // سيتم تحديثه
          lastMessage: msg.content,
          lastMessageTime: msg.timestamp,
        ),
      );
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  //  CURRENT CHAT
  // ═══════════════════════════════════════════════════

  void setCurrentChat(ChatModel? chat) {
    _currentChat = chat;
    if (chat != null) {
      _unreadChats.remove(chat.userId);
      loadMessages(chat.userId);
      _ws.requestPresence([chat.userId]);
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  //  TYPING
  // ═══════════════════════════════════════════════════

  void sendTyping(int receiverId) {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!).inSeconds < 2) {
      return; // لا ترسل كثير
    }
    _lastTypingSent = now;
    _ws.sendTyping(receiverId: receiverId);
  }

  // ═══════════════════════════════════════════════════
  //  SEARCH
  // ═══════════════════════════════════════════════════

  Future<List<UserModel>> searchUsers(String query) async {
    if (_token == null) return [];
    return _api.searchUsers(query: query, token: _token!);
  }

  // ═══════════════════════════════════════════════════
  //  PRESENCE
  // ═══════════════════════════════════════════════════

  void _requestPresenceForChats() {
    final uids = _chats.map((c) => c.userId).toList();
    if (uids.isNotEmpty) {
      _ws.requestPresence(uids);
    }
  }

  // ═══════════════════════════════════════════════════
  //  LOGOUT
  // ═══════════════════════════════════════════════════

  void disconnect() {
    _ws.announcePresence(online: false);
    _ws.disconnect();
    _chats.clear();
    _messages.clear();
    _presence.clear();
    _lastSeen.clear();
    _typingUsers.clear();
    _unreadChats.clear();
    _currentChat = null;
    _token = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ws.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}
