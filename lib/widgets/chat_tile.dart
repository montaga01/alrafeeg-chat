import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class ChatTile extends StatelessWidget {
  final String        name;
  final String        lastMessage;
  final String        timestamp;
  final bool          hasUnread;    // ✅ نقطة الرسالة غير المقروءة
  final VoidCallback  onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.onTap,
    this.hasUnread = false,
  });

  String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return DateFormat('HH:mm').format(dt);
    if (today.difference(msgDay).inDays == 1) return 'أمس';
    if (today.difference(msgDay).inDays < 7)  return DateFormat('EEE', 'ar').format(dt);
    return DateFormat('d/M').format(dt);
  }

  // لوان أفاتار ديناميكية حسب الحرف الأول
  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF1A73E8), const Color(0xFF00897B),
      const Color(0xFF7B1FA2), const Color(0xFFE53935),
      const Color(0xFFF57C00), const Color(0xFF388E3C),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color   = _avatarColor(name.isNotEmpty ? name : '?');
    final timeStr = _formatTime(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── الأفاتار ─────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.3),
                            blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                  // نقطة الرسالة غير المقروءة
                  if (hasUnread)
                    Positioned(
                      bottom: 2, right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── نص ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1A237E),
                            )),
                        Text(timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? const Color(0xFF1A73E8)
                                  : Colors.grey,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread ? Colors.black87 : Colors.grey,
                              fontSize: 13,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
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
}
