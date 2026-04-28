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
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _ws         = WebSocketService(); // singleton

  List<Message> _messages = [];
  int  _myId   = 0;
  bool _loading = true;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = await AppStorage.getUserId() ?? 0;

    // ── تحميل الرسائل من السيرفر (مرة واحدة فقط) ────────────
    try {
      final msgs = await ApiService.getMessages(widget.otherUser.id);
      if (!mounted) return;
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom(jump: true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // ── استماع للرسائل الجديدة push (بدون إعادة تحميل كامل) ──
    _wsSub = _ws.messages.listen((msg) {
      final otherUid = widget.otherUser.id;
      final relevant = (msg.senderId == otherUid && msg.receiverId == _myId)
                    || (msg.senderId == _myId    && msg.receiverId == otherUid);
      if (!relevant) return;

      // لا نضيف مكرراً (optimistic + confirmed)
      if (_messages.any((m) => m.id == msg.id && msg.id != 0)) return;

      setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    // Optimistic update فوري
    final tempId  = -DateTime.now().millisecondsSinceEpoch;
    final tempMsg = Message(
      id:         tempId,
      senderId:   _myId,
      receiverId: widget.otherUser.id,
      content:    text,
      timestamp:  DateTime.now(),
    );
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    // إرسال عبر WebSocket أو HTTP
    try {
      _ws.sendMessage(receiverId: widget.otherUser.id, content: text);
    } catch (_) {
      ApiService.sendMessage(receiverId: widget.otherUser.id, content: text)
          .catchError((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('فشل الإرسال')));
        }
      });
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (jump) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  بناء القائمة مع فواصل التاريخ
  // ══════════════════════════════════════════════════════════════
  List<Widget> _buildMessageList() {
    final items = <Widget>[];
    DateTime? lastDay;

    for (final msg in _messages) {
      final day = DateTime(
          msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);

      // فاصل يوم جديد
      if (lastDay == null || day != lastDay) {
        items.add(DateDivider(date: msg.timestamp));
        lastDay = day;
      }

      items.add(MessageBubble(
        message: msg,
        isMe:    msg.senderId == _myId,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: Text(widget.otherUser.name[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.name,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const Text('متصل',
                    style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ── الرسائل ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('ابدأ المحادثة! 👋',
                            style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _buildMessageList(),
                      ),
          ),

          // ── حقل الإرسال ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:      _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted:     (_) => _send(),
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
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48, height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
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
