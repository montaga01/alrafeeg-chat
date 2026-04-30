import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String timestamp;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(timestamp)?.toLocal();
    final timeStr = dt != null ? DateFormat('hh:mm a').format(dt) : '';
  
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          // تجعل العناصر تبدأ من اليمين (في حالة الـ RTL)
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. الدائرة الشخصية (تبقي في اليمين)
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF1a56db).withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1a56db),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
  
            // 2. العمود الذي يحتوي على الاسم والرسالة (يتمدد ليأخذ كل المساحة المتاحة)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة النص لليمين (بداية العمود)
                children: [
                  Text(name,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF1a2340),
                      )),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.tajawal(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
  
            // 3. الوقت (سيدفع تلقائياً لأقصى الشمال بفضل Expanded في العنصر السابق)
            Padding(
              padding: const EdgeInsets.only(right: 8.0), // مسافة بسيطة بين النص والوقت
              child: Text(
                timeStr,
                style: GoogleFonts.tajawal(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}