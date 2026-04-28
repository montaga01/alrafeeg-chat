import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../core/theme.dart';

// ══════════════════════════════════════════════════════════════
//  فاصل التاريخ بين أيام مختلفة
// ══════════════════════════════════════════════════════════════
class DateDivider extends StatelessWidget {
  final DateTime date;
  const DateDivider({super.key, required this.date});

  String _label() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    if (d == today)                         return 'اليوم';
    if (d == today.subtract(const Duration(days: 1))) return 'أمس';
    if (today.difference(d).inDays < 7)    return DateFormat('EEEE', 'ar').format(date);
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(_label(),
              style: const TextStyle(color: Colors.grey, fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  فقاعة الرسالة
//  • المستخدم (أنا)  → يمين  — أزرق
//  • الطرف الآخر     → يسار  — أبيض/رمادي فاتح
//  • الوقت دائماً في اليسار داخل الفقاعة
// ══════════════════════════════════════════════════════════════
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool    isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  String _timeLabel() {
    final now   = DateTime.now();
    final local = message.timestamp.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);

    if (msgDay == today) {
      // نفس اليوم → الوقت فقط
      return DateFormat('HH:mm').format(local);
    } else {
      // يوم ثاني → نعرض التاريخ
      if (today.difference(msgDay).inDays < 7) {
        return DateFormat('EEE', 'ar').format(local); // اسم اليوم مختصر
      }
      return DateFormat('d/M').format(local);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      // أنا → يمين، غيري → يسار
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3, bottom: 3,
          right: isMe ? 12 : 60,
          left:  isMe ? 60 : 12,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.bubbleMe : AppTheme.bubbleOther,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // المحتوى يبدأ من اليسار دائماً
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            // الوقت → يسار دائماً
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _timeLabel(),
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white60 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
