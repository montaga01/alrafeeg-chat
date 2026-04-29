import 'package:flutter/material.dart';
import '../models/chat.dart';
import 'avatar_widget.dart';

/// عنصر المحادثة في القائمة الجانبية
class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final bool isActive;
  final bool hasUnread;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    this.isActive = false,
    this.hasUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF21262D) : const Color(0xFFF0F2F5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF30363D)
                        : const Color(0xFFD0D7DE),
                  )
                : null,
          ),
          child: Row(
            children: [
              // الأفاتار
              AvatarWidget(
                name: chat.name,
                size: 42,
                isOnline: chat.isOnline,
              ),
              const SizedBox(width: 12),

              // معلومات المحادثة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessageTime != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              _formatTime(chat.lastMessageTime!),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF8B949E)
                                    : const Color(0xFF656D76),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF8B949E)
                                  : const Color(0xFF656D76),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F81F7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F81F7)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    if (day == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    }
    final diff = today.difference(day).inDays;
    if (diff < 7) {
      const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
