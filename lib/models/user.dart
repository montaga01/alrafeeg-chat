class UserModel {
  final int id;
  final String name;
  final String email;
  final String? fcmToken;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.fcmToken,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'fcm_token': fcmToken,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// أول حرف من الاسم للأفاتار
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
