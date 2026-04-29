import 'package:flutter/material.dart';
import '../models/user.dart';
import 'avatar_widget.dart';

/// نتيجة البحث عن مستخدم
class UserSearchResult extends StatelessWidget {
  final UserModel user;
  final bool isOnline;
  final VoidCallback onTap;

  const UserSearchResult({
    super.key,
    required this.user,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              AvatarWidget(
                name: user.name,
                size: 36,
                isOnline: isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'ID: ${user.id}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF656D76),
                          ),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '● متصل',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF3FB950),
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
