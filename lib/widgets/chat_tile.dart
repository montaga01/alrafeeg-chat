import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

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

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: Text(timeStr,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
