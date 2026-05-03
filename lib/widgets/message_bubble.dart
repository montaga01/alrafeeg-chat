import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/message.dart';

// ═══════════════════════════════════════════════════
//  MESSAGE BUBBLE
//  نفس منطق bubbleHtml() من صفحة الويب
// ═══════════════════════════════════════════════════
class MessageBubble extends StatelessWidget {
  final Message      message;
  final bool         isMe;
  final bool         isFirstInGroup;
  final bool         isLastInGroup;
  final bool         isPending;
  final bool         hasFailed;
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

  // ── تنسيق الوقت من DateTime مباشرة ──
  String _fmtTime(DateTime ts) =>
      DateFormat('HH:mm').format(ts.toLocal());

  // ── شكل الزوايا حسب الجهة ──
  BorderRadius _radius() {
    const r  = Radius.circular(18);
    const r4 = Radius.circular(4);
    if (isMe) {
      return BorderRadius.only(
        topLeft:     r,
        topRight:    r,
        bottomLeft:  r,
        bottomRight: r4,
      );
    }
    return BorderRadius.only(
      topLeft:     r,
      topRight:    r,
      bottomLeft:  r4,
      bottomRight: r,
    );
  }

  BoxDecoration _decoration(AppColorScheme c) {
    if (isMe) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [c.bubbleMe1, c.bubbleMe2],
        ),
        borderRadius: _radius(),
      );
    }
    return BoxDecoration(
      color:        c.bubbleOther,
      border:       Border.all(color: c.bubbleOtherBorder),
      borderRadius: _radius(),
      boxShadow: [
        BoxShadow(
          color:      Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset:     const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c       = AppColors.of(context);
    final timeStr = _fmtTime(message.timestamp);

    return Column(
      // ✅ الإصلاح الرئيسي: crossAxisAlignment يحدد الجهة
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Align يضمن الجهة الصحيحة دايماً
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top:    isFirstInGroup ? 6 : 2,
              right:  isMe  ? 12 : 52,
              left:   isMe  ? 52 : 12,
            ),
            // ✅ maxWidth يمنع امتداد الفقاعة للعرض الكامل
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: GestureDetector(
              onLongPress: () => _onLongPress(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 9,
                ),
                decoration: _decoration(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ بدون textDirection — التطبيق RTL من MaterialApp
                    Text(
                      message.content,
                      style: AppTextStyles.bubbleText(isMe: isMe, c: c),
                    ),
                    const SizedBox(height: 4),
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
          ),
        ),

        // ── زر إعادة الإرسال ──
        if (hasFailed && onRetry != null)
          Padding(
            padding: EdgeInsets.only(
              right: isMe ? 14 : 0,
              left:  isMe ? 0  : 14,
              top:   3,
            ),
            child: GestureDetector(
              onTap: onRetry,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: c.red),
                  const SizedBox(width: 3),
                  Text(
                    'إعادة الإرسال',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11, color: c.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  STATUS ICON
// ═══════════════════════════════════════════════════
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
    if (hasFailed) {
      return Icon(Icons.error_outline_rounded, size: 13, color: c.red);
    }
    if (isPending) {
      return const Icon(Icons.access_time_rounded,
          size: 13, color: Colors.white54);
    }
    return const Icon(Icons.done_all_rounded,
        size: 13, color: Colors.white70);
  }
}

// ═══════════════════════════════════════════════════
//  EXTENSION — copyWith لـ BoxDecoration
// ═══════════════════════════════════════════════════
extension BoxDecorationX on BoxDecoration {
  BoxDecoration copyWith({
    Color?                color,
    DecorationImage?      image,
    BoxBorder?            border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>?      boxShadow,
    Gradient?             gradient,
    BlendMode?            backgroundBlendMode,
    BoxShape?             shape,
  }) {
    return BoxDecoration(
      color:               color               ?? this.color,
      image:               image               ?? this.image,
      border:              border              ?? this.border,
      borderRadius:        borderRadius        ?? this.borderRadius,
      boxShadow:           boxShadow           ?? this.boxShadow,
      gradient:            gradient            ?? this.gradient,
      backgroundBlendMode: backgroundBlendMode ?? this.backgroundBlendMode,
      shape:               shape               ?? this.shape,
    );
  }
}