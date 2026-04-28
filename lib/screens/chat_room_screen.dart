import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/date_formatter.dart';

class ChatRoomScreen extends StatefulWidget {
  final Chat chat;
  final String token;

  const ChatRoomScreen({
    super.key,
    required this.chat,
    required this.token,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(
      receiverId: widget.chat.userId,
      content: text,
      token: widget.token,
    );

    _messageController.clear();
    _focusNode.requestFocus();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages[widget.chat.userId] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFf8faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(widget.chat.initial),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a2340),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF22c55e),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'متصل',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFe2e8f8), height: 1),
        ),
      ),
      body: Column(
        children: [
          // الرسائل
          Expanded(
            child: chatProvider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'ابدأ المحادثة! 👋',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF94a3b8),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: messages.length + _countDayDividers(messages),
                        itemBuilder: (context, index) {
                          return _buildMessageItem(messages, index);
                        },
                      ),
          ),

          // مؤشر الكتابة
          if (false) // TODO: إضافة مؤشر الكتابة
            _buildTypingIndicator(),

          // حقل الإدخال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFe2e8f8)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.right,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFe2e8f8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFe2e8f8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF1a56db),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFf8faff),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1a56db), Color(0xFF1e429f)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1a56db).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: _sendMessage,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countDayDividers(List<Message> messages) {
    int count = 0;
    DateTime? lastDay;
    for (final msg in messages) {
      final day = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDay == null || day != lastDay) {
        count++;
        lastDay = day;
      }
    }
    return count;
  }

  Widget _buildMessageItem(List<Message> messages, int index) {
    // حساب الرسالة الفعلية وفواصل الأيام
    int msgIndex = 0;
    int dividerCount = 0;
    DateTime? lastDay;

    for (int i = 0; i <= msgIndex; i++) {
      if (i < messages.length) {
        final day = DateTime(
          messages[i].timestamp.year,
          messages[i].timestamp.month,
          messages[i].timestamp.day,
        );
        if (lastDay == null || day != lastDay) {
          dividerCount++;
          lastDay = day;
        }
      }
    }

    // إعادة الحساب بشكل أبسط
    int actualMsgIndex = 0;
    lastDay = null;

    for (int i = 0; i < messages.length; i++) {
      final day = DateTime(
        messages[i].timestamp.year,
        messages[i].timestamp.month,
        messages[i].timestamp.day,
      );
      if (lastDay == null || day != lastDay) {
        if (actualMsgIndex + dividerCount == index) {
          return _buildDayDivider(messages[i].timestamp);
        }
        dividerCount++;
        lastDay = day;
      }
      if (actualMsgIndex + dividerCount == index) {
        return _buildMessageBubble(messages[i]);
      }
      actualMsgIndex++;
    }

    return const SizedBox.shrink();
  }

  Widget _buildDayDivider(DateTime timestamp) {
    final label = DateFormatter.getDayLabel(timestamp);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFe2e8f8))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFe2e8f8)),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFe2e8f8))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId.toString() != widget.chat.userId.toString();
    final time = DateFormatter.formatTime(message.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildSmallAvatar(widget.chat.initial),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF1a56db), Color(0xFF1e429f)],
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFe2e8f8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isMe ? Colors.white : const Color(0xFF1a2340),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isMe
                              ? Colors.white.withOpacity(0.65)
                              : const Color(0xFF64748b),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: message.isTemp
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initial) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFc7d7ff), Color(0xFFe0e7ff)],
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a56db),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(String initial) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFc7d7ff), Color(0xFFe0e7ff)],
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a56db),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSmallAvatar(widget.chat.initial),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFe2e8f8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF64748b),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
