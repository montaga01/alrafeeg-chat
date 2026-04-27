import 'dart:async';
import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl      = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _wsService    = WebSocketService();

  List<Message> _messages = [];
  int _myId = 0;
  bool _loading = true;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = await AppStorage.getUserId() ?? 0;
    final token = await AppStorage.getToken() ?? '';

    // تحميل الرسائل القديمة
    try {
      final msgs = await ApiService.getMessages(widget.otherUser.id);
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    } catch (_) {
      setState(() => _loading = false);
    }

    // الاتصال بـ WebSocket
    _wsService.connect(token);
    _wsSub = _wsService.messages.listen((msg) {
      // نقبل فقط الرسائل المتعلقة بهذه المحادثة
      if (msg.senderId == widget.otherUser.id || msg.receiverId == widget.otherUser.id) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    });
  }

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    // إضافة الرسالة محلياً فوراً (optimistic update)
    final tempMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: _myId,
      receiverId: widget.otherUser.id,
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      // إرسال عبر WebSocket
      _wsService.sendMessage(
        receiverId: widget.otherUser.id,
        content: text,
      );
    } catch (_) {
      // fallback: إرسال عبر HTTP
      try {
        await ApiService.sendMessage(
          receiverId: widget.otherUser.id,
          content: text,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الإرسال: $e')));
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsService.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: Text(
                widget.otherUser.name[0].toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('ابدأ المحادثة! 👋',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => MessageBubble(
                          message: _messages[i],
                          isMe: _messages[i].senderId == _myId,
                        ),
                      ),
          ),

          // حقل الإرسال
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
