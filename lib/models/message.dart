class Message {
  final int      id;
  final int      senderId;
  final int      receiverId;
  final String   content;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id:         j['id']         ?? 0,
    senderId:   j['sender_id']  ?? 0,
    receiverId: j['receiver_id'] ?? 0,
    content:    j['content']    ?? '',
    timestamp:  DateTime.tryParse(j['timestamp'] ?? '')?.toLocal() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'sender_id':   senderId,
    'receiver_id': receiverId,
    'content':     content,
    'timestamp':   timestamp.toIso8601String(),
  };
}
