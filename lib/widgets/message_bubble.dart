import 'dart:ui' as ui; // حل مشكلة التعرف على الاتجاه في الـ CI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/message.dart';

// ═══════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ═══════════════════════════════════════════════════
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool    isMe;
  final bool    isFirstInGroup;
  final bool    isLastInGroup;
  final bool    isPending;
  final bool    hasFailed;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInGroup = true,
    this.isLastInGroup  = true,
    this.isPending      = false,
    this.hasFailed      = false,
    this.onRetry,
  });

  // ── منطق حواف الفقاعة ──
  BorderRadius _radius() {
    const r  = Radius.circular(18);
    const r4 = Radius.circular(4);

    if (isMe) {
      return BorderRadius.only(
        topLeft:     r,
        topRight:    isFirstInGroup ? r : r4,
        bottomLeft:  r,
        bottomRight: isLastInGroup  ? r4 : r4,
      );
    } else {
      return BorderRadius.only(
        topLeft:     isFirstInGroup ? r : r4,
        topRight:    r,
        bottomLeft:  isLastInGroup  ? r4 : r4,
        bottomRight: r,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c       = AppColors.of(context);
    // تنسيق الوقت باستخدام مكتبة intl
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Padding(
      padding: EdgeInsets.only(
        top:    isFirstInGroup ? 8 : 2,
        bottom: isLastInGroup  ? 2 : 0,
        left:   isMe  ? 60 : 14,
        right:  isMe  ? 14 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _onLongPress(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: isMe
                  ? AppDecorations.bubbleMe(c).copyWith(
                      borderRadius: _radius(),
                    )
                  : AppDecorations.bubbleOther(c).copyWith(
                      borderRadius: _radius(),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // نص الرسالة مع تحديد الاتجاه بشكل صارم
                  Text(
                    message.content,
                    style: AppTextStyles.bubbleText(isMe: isMe, c: c),
                    textDirection: ui.TextDirection.rtl, 
                  ),
                  const SizedBox(height: 4),

                  // الوقت وحالة الإرسال
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: AppTextStyles.bubbleTime(isMe: isMe),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _StatusIcon(
                          isPending: isPending,
                          hasFailed: hasFailed,
                          c:         c,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // زر إعادة الإرسال في حالة الفشل
          if (hasFailed && onRetry != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: c.red),
                  const SizedBox(width: 3),
                  Text(
                    'إعادة الإرسال',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11,
                      color:    c.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onLongPress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الرسالة',
          style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
        ),
        duration:        const Duration(seconds: 2),
        backgroundColor: AppColors.of(context).bg3,
        behavior:        SnackBarBehavior.floating,
      ),
    );
  }
}

// ── أيقونة الحالة ──
class _StatusIcon extends StatelessWidget {
  final bool           isPending;
  final bool           hasFailed;
  final AppColorScheme c;

  const _StatusIcon({
    required this.isPending,
    required this.hasFailed,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    if (hasFailed) return Icon(Icons.error_outline_rounded, size: 13, color: c.red);
    if (isPending) return const Icon(Icons.access_time_rounded, size: 13, color: Colors.white54);
    return const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70);
  }
}

// ── Extension لتعديل الـ Decoration ──
extension BoxDecorationX on BoxDecoration {
  BoxDecoration copyWith({
    Color?             color,
    DecorationImage?   image,
    BoxBorder?         border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>?   boxShadow,
    Gradient?          gradient,
    BlendMode?         backgroundBlendMode,
    BoxShape?          shape,
  }) {
    return BoxDecoration(
      color:                color             ?? this.color,
      image:                image             ?? this.image,
      border:               border            ?? this.border,
      borderRadius:         borderRadius      ?? this.borderRadius,
      boxShadow:            boxShadow         ?? this.boxShadow,
      gradient:             gradient          ?? this.gradient,
      backgroundBlendMode:  backgroundBlendMode ?? this.backgroundBlendMode,
      shape:                shape             ?? this.shape,
    );
  }
}
