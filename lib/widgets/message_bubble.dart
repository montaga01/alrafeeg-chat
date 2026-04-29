import 'package:flutter/material.dart';
import '../models/message.dart';

/// فقاعة الرسالة مع تصميم حديث
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showDate;
  final String? dateLabel;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showDate = false,
    this.dateLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // فاصل التاريخ
        if (showDate && dateLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF21262D)
                          : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF30363D)
                            : const Color(0xFFD0D7DE),
                      ),
                    ),
                    child: Text(
                      dateLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8B949E)
                            : const Color(0xFF656D76),
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),

        // الفقاعة
        Align(
          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(
              left: isMe ? 48 : 16,
              right: isMe ? 16 : 48,
              bottom: 4,
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2F81F7), Color(0xFF1F6FEB)],
                          )
                        : null,
                    color: isMe
                        ? null
                        : isDark
                            ? const Color(0xFF21262D)
                            : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 4 : 18),
                      bottomRight: Radius.circular(isMe ? 18 : 4),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark
                                ? const Color(0xFF30363D)
                                : const Color(0xFFD0D7DE),
                          ),
                    boxShadow: isMe
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2F81F7)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : isDark
                                  ? const Color(0xFFE6EDF3)
                                  : const Color(0xFF1F2328),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : isDark
                                      ? const Color(0xFF8B949E)
                                      : const Color(0xFF656D76),
                            ),
                          ),
                          // حالة الرسالة
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(message.status),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // زر إعادة الإرسال للرسائل الفاشلة
                if (isMe && message.status == MessageStatus.failed)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('إعادة إرسال', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFFF85149),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Color(0x80FFFFFF));
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Color(0x80FFFFFF));
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Color(0xFFF85149));
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
