import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/message.dart';
import '../widgets/widgets.dart';

/// شاشة المحادثة الفردية
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showScrollBtn = false;
  DateTime? _lastTypingSent;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollCtrl.position.pixels <
        _scrollCtrl.position.maxScrollExtent - 200;
    if (show != _showScrollBtn) {
      setState(() => _showScrollBtn = show);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currentChat = chat.currentChat;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentChat == null) {
      return const SizedBox.shrink();
    }

    final messages = chat.messagesForChat(currentChat.userId);
    final isTyping = chat.isUserTyping(currentChat.userId);
    final isOnline = chat.isUserOnline(currentChat.userId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Header مخصص
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF30363D)
                      : const Color(0xFFD0D7DE),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // زر الرجوع
                    IconButton(
                      onPressed: () {
                        chat.setCurrentChat(null);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'رجوع',
                    ),
                    const SizedBox(width: 4),

                    // الأفاتار مع حالة الاتصال
                    Stack(
                      children: [
                        AvatarWidget(
                          name: currentChat.name,
                          size: 36,
                          isOnline: isOnline,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // الاسم والحالة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentChat.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFE6EDF3)
                                  : const Color(0xFF1F2328),
                            ),
                          ),
                          // مؤشر الكتابة أو حالة الاتصال
                          if (isTyping)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: _MiniTypingDots(),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'يكتب...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2F81F7),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              isOnline ? 'متصل' : 'آخر ظهور مؤخراً',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOnline
                                    ? const Color(0xFF3FB950)
                                    : isDark
                                        ? const Color(0xFF8B949E)
                                        : const Color(0xFF656D76),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // الرسائل
        body: Column(
          children: [
            // قائمة الرسائل
            Expanded(
              child: chat.isLoadingMessages && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? _buildEmptyChat(isDark)
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (ctx, i) {
                                final msg = messages[i];
                                final isMe = msg.senderId == chat.myId;

                                // فاصل التاريخ
                                String? dateLabel;
                                bool showDate = false;
                                if (i == 0) {
                                  showDate = true;
                                  dateLabel = _dayLabel(msg.timestamp);
                                } else {
                                  final prev = messages[i - 1];
                                  if (!_sameDay(prev.timestamp, msg.timestamp)) {
                                    showDate = true;
                                    dateLabel = _dayLabel(msg.timestamp);
                                  }
                                }

                                return MessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  showDate: showDate,
                                  dateLabel: dateLabel,
                                  onRetry: msg.status == MessageStatus.failed
                                      ? () => chat.retryMessage(
                                            msg.receiverId == chat.myId
                                                ? msg.senderId
                                                : msg.receiverId,
                                            msg.id,
                                          )
                                      : null,
                                );
                              },
                            ),

                            // زر التمرير للأسفل
                            if (_showScrollBtn)
                              Positioned(
                                left: 16,
                                bottom: 8,
                                child: FloatingActionButton.small(
                                  onPressed: _scrollToBottom,
                                  backgroundColor: isDark
                                      ? const Color(0xFF21262D)
                                      : Colors.white,
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: isDark
                                        ? const Color(0xFF8B949E)
                                        : const Color(0xFF656D76),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),

            // مؤشر الكتابة
            if (isTyping) const TypingIndicator(),

            // منطقة الإدخال
            _buildInputArea(chat, currentChat.userId, isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  EMPTY CHAT STATE
  // ═══════════════════════════════════════════════════
  Widget _buildEmptyChat(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '👋',
            style: TextStyle(
              fontSize: 48,
              color: isDark
                  ? const Color(0xFF484F58)
                  : const Color(0xFF8B949E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ابدأ المحادثة!',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF484F58)
                  : const Color(0xFF8B949E),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  INPUT AREA
  // ═══════════════════════════════════════════════════
  Widget _buildInputArea(ChatProvider chat, int receiverId, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // حقل الإدخال
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _msgCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                  onChanged: (_) {
                    // إرسال مؤشر الكتابة
                    final now = DateTime.now();
                    if (_lastTypingSent == null ||
                        now.difference(_lastTypingSent!).inSeconds >= 2) {
                      _lastTypingSent = now;
                      chat.sendTyping(receiverId);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),

            // زر الإرسال
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2F81F7), Color(0xFF1F6FEB)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F81F7).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _sendMessage(chat, receiverId),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SEND MESSAGE
  // ═══════════════════════════════════════════════════
  void _sendMessage(ChatProvider chat, int receiverId) {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    chat.sendMessage(receiverId: receiverId, content: text);

    // تمرير للأسفل
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  // ═══════════════════════════════════════════════════
  //  DATE HELPERS
  // ═══════════════════════════════════════════════════
  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    if (day == today) return 'اليوم';
    if (day == today.subtract(const Duration(days: 1))) return 'أمس';
    final diff = today.difference(day).inDays;
    if (diff < 7) {
      const days = [
        'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
        'الجمعة', 'السبت', 'الأحد'
      ];
      return days[dt.weekday - 1];
    }
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[m];
  }
}

/// أنيميشن صغير لمؤشر الكتابة في الـ Header
class _MiniTypingDots extends StatefulWidget {
  const _MiniTypingDots();

  @override
  State<_MiniTypingDots> createState() => _MiniTypingDotsState();
}

class _MiniTypingDotsState extends State<_MiniTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final progress =
                (_ctrl.value + i * 0.15) % 1.0;
            return Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF2F81F7)
                    .withValues(alpha: 0.4 + 0.6 * progress),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// AnimatedBuilder
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
