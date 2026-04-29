class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  MessageStatus status;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int? ?? 0,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      content: json['content'] as String,
      timestamp: _parseTimestamp(json['timestamp']),
      status: MessageStatus.sent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
    };
  }

  factory MessageModel.fromDbMap(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values[json['status'] as int? ?? 0],
    );
  }

  bool get isMe => false; // يتم تعيينها في الـ provider

  static DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now();
    final str = ts.toString();
    if (str.contains('Z') || str.contains('+')) {
      return DateTime.parse(str);
    }
    return DateTime.parse('${str}Z');
  }

  MessageModel copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus {
  sending,   // جاري الإرسال
  sent,      // تم الإرسال
  failed,    // فشل الإرسال
  delivered, // تم التسليم
}
