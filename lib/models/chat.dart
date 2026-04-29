import 'message.dart';

class ChatModel {
  final int userId;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  int unreadCount;
  bool isOnline;
  DateTime? lastSeen;

  ChatModel({
    required this.userId,
    required this.name,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'مستخدم',
      lastMessage: json['content'] as String?,
      lastMessageTime: json['timestamp'] != null
          ? _parseTimestamp(json['timestamp'])
          : null,
      isOnline: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'content': lastMessage,
      'timestamp': lastMessageTime?.toIso8601String(),
    };
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  ChatModel copyWith({
    int? userId,
    String? name,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ChatModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    final str = ts.toString();
    if (str.contains('Z') || str.contains('+')) {
      return DateTime.parse(str);
    }
    return DateTime.parse('${str}Z');
  }
}
