import 'message.dart';

class Chat {
  int userId;
  String name;
  String? lastMessage;
  DateTime? timestamp;
  int unreadCount;

  Chat({
    required this.userId,
    required this.name,
    this.lastMessage,
    this.timestamp,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      lastMessage: json['content'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
    );
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  void updateFromMessage(Message msg) {
    lastMessage = msg.content;
    timestamp = msg.timestamp;
  }
}
