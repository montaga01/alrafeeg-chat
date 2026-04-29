import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/message.dart';

/// خدمة التخزين المحلي للرسائل
/// تخزّن الرسائل في SQLite عشان ما نحتاج نحمّلها كل مرة من السيرفر
class StorageService {
  static Database? _db;
  static const String _dbName = 'alrafeeg.db';
  static const int _dbVersion = 2;

  /// فتح/إنشاء قاعدة البيانات
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY,
            sender_id INTEGER NOT NULL,
            receiver_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            status INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_conversation 
          ON messages (sender_id, receiver_id)
        ''');

        await db.execute('''
          CREATE TABLE chat_meta (
            user_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            last_message TEXT,
            last_message_time TEXT,
            unread_count INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_meta (
              user_id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              last_message TEXT,
              last_message_time TEXT,
              unread_count INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════

  /// حفظ رسالة واحدة
  Future<void> saveMessage(MessageModel msg) async {
    final db = await database;
    await db.insert(
      'messages',
      msg.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// حفظ مجموعة رسائل
  Future<void> saveMessages(List<MessageModel> msgs) async {
    final db = await database;
    final batch = db.batch();
    for (final msg in msgs) {
      batch.insert(
        'messages',
        msg.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// جلب الرسائل المحلية مع مستخدم
  Future<List<MessageModel>> getMessages(int myId, int withUserId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [myId, withUserId, withUserId, myId],
      orderBy: 'timestamp ASC',
    );
    return rows.map((r) => MessageModel.fromDbMap(r)).toList();
  }

  /// جلب آخر رسالة مع مستخدم
  Future<MessageModel?> getLastMessage(int myId, int withUserId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [myId, withUserId, withUserId, myId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MessageModel.fromDbMap(rows.first);
  }

  /// جلب آخر رسالة لكل محادثة
  Future<List<Map<String, dynamic>>> getAllLastMessages(int myId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT m.* FROM messages m
      INNER JOIN (
        SELECT 
          CASE WHEN sender_id = ? THEN receiver_id ELSE sender_id END as peer_id,
          MAX(timestamp) as max_ts
        FROM messages
        WHERE sender_id = ? OR receiver_id = ?
        GROUP BY peer_id
      ) latest ON m.timestamp = latest.max_ts
      AND (
        (m.sender_id = ? AND m.receiver_id = latest.peer_id) OR
        (m.receiver_id = ? AND m.sender_id = latest.peer_id)
      )
      ORDER BY m.timestamp DESC
    ''', [myId, myId, myId, myId, myId]);
    return rows;
  }

  /// جلب عدد الرسائل لمعرفة آخر ID محفوظ
  Future<int> getLatestMessageId(int myId, int withUserId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [myId, withUserId, withUserId, myId],
      orderBy: 'id DESC',
      limit: 1,
      columns: ['id'],
    );
    if (rows.isEmpty) return 0;
    return rows.first['id'] as int;
  }

  /// تحديث حالة الرسالة
  Future<void> updateMessageStatus(int msgId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [msgId],
    );
  }

  /// حذف رسائل محادثة معينة
  Future<void> deleteMessages(int myId, int withUserId) async {
    final db = await database;
    await db.delete(
      'messages',
      where:
          '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [myId, withUserId, withUserId, myId],
    );
  }

  // ═══════════════════════════════════════════════════
  //  CHAT META
  // ═══════════════════════════════════════════════════

  /// حفظ/تحديث بيانات المحادثة
  Future<void> saveChatMeta(Map<String, dynamic> meta) async {
    final db = await database;
    await db.insert(
      'chat_meta',
      meta,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// جلب بيانات المحادثات المحلية
  Future<List<Map<String, dynamic>>> getChatMetas() async {
    final db = await database;
    return db.query('chat_meta', orderBy: 'last_message_time DESC');
  }

  /// تحديث عداد الرسائل غير المقروءة
  Future<void> updateUnreadCount(int userId, int count) async {
    final db = await database;
    await db.update(
      'chat_meta',
      {'unread_count': count},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ═══════════════════════════════════════════════════
  //  CLEANUP
  // ═══════════════════════════════════════════════════

  /// حذف كل البيانات المحلية
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chat_meta');
  }
}
