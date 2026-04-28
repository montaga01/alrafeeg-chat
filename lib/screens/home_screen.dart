import 'dart:async';
import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _chats       = [];
  final Set<int>             _unreadSenders = {}; // معرفات المرسلين الجدد
  bool   _loading = true;
  String _myName  = '';
  int    _myId    = 0;
  final  _ws      = WebSocketService();
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myName = await AppStorage.getUserName() ?? '';
    _myId   = await AppStorage.getUserId()   ?? 0;
    final token = await AppStorage.getToken() ?? '';

    // ── تحميل أولي من السيرفر ───────────────────────────────────
    await _loadChats();

    // ── اتصال WebSocket مركزي ─────────────────────────────────
    _ws.connect(token);

    // ── الاستماع للرسائل الواردة push ───────────────────────────
    _wsSub = _ws.messages.listen((msg) {
      // رسالة من شخص آخر → حدّث قائمة المحادثات بدون طلب جديد
      final senderId = msg.senderId;
      if (senderId == _myId) return; // رسالتي أنا

      setState(() {
        _unreadSenders.add(senderId);
        // أضف أو حرّك المحادثة للأعلى
        _chats.removeWhere((c) => c['user_id'] == senderId);
        _chats.insert(0, {
          'user_id':   senderId,
          'name':      msg.content.isNotEmpty ? '...' : '...',
          'content':   msg.content,
          'timestamp': msg.timestamp.toIso8601String(),
        });
      });

      // جلب اسم المُرسِل إذا لم يكن موجوداً
      _resolveUserName(senderId);
    });
  }

  // جلب اسم المستخدم من قائمة المحادثات الكاملة عند وصول رسالة جديدة
  Future<void> _resolveUserName(int userId) async {
    try {
      final chats = await ApiService.getChats();
      if (!mounted) return;
      setState(() {
        for (final c in chats) {
          final idx = _chats.indexWhere((x) => x['user_id'] == c['user_id']);
          if (idx != -1) {
            _chats[idx] = {..._chats[idx], 'name': c['name']};
          } else {
            _chats.insert(0, c);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ApiService.getChats();
      if (!mounted) return;
      setState(() { _chats = chats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChat(ChatUser user) async {
    setState(() => _unreadSenders.remove(user.id));
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
    // بعد العودة نحدّث القائمة من السيرفر مرة واحدة
    _loadChats();
  }

  void _openSearch() async {
    final user = await showSearch<ChatUser?>(
      context: context,
      delegate: _UserSearchDelegate(),
    );
    if (user != null && mounted) _openChat(user);
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('خروج', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      _ws.disconnect();
      _wsSub?.cancel();
      await AppStorage.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),

      // ── AppBar ─────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('الرفيق',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E))),
            Text('مرحباً، $_myName 👋',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF1A73E8)),
              onPressed: _openSearch),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.grey),
              onPressed: _logout),
        ],
      ),

      // ── Body ────────────────────────────────────────────────────
      body: Column(
        children: [
          // رأس ملوّن
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المحادثات (${_chats.length})',
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                if (_unreadSenders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_unreadSenders.length} جديد',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // قائمة المحادثات
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _chats.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _chats.length,
                          itemBuilder: (_, i) {
                            final chat = _chats[i];
                            final uid  = chat['user_id'] as int? ?? 0;
                            return ChatTile(
                              name:        chat['name'] ?? 'مستخدم',
                              lastMessage: chat['content'] ?? '',
                              timestamp:   chat['timestamp'] ?? '',
                              hasUnread:   _unreadSenders.contains(uid),
                              onTap: () => _openChat(ChatUser(
                                id:    uid,
                                name:  chat['name'] ?? 'مستخدم',
                                email: '',
                              )),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSearch,
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 6,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('محادثة جديدة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 52, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('لا توجد محادثات بعد',
              style: TextStyle(color: Color(0xFF1A237E), fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ابحث عن مستخدم لبدء محادثة',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Search Delegate
// ══════════════════════════════════════════════════════════════
class _UserSearchDelegate extends SearchDelegate<ChatUser?> {
  List<ChatUser> _results  = [];
  String         _lastQuery = '';

  @override
  String get searchFieldLabel => 'ابحث باسم أو ID...';

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearch(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('ابحث باسم المستخدم أو رقم الـ ID',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return _buildSearch(context);
  }

  Widget _buildSearch(BuildContext context) {
    return FutureBuilder<List<ChatUser>>(
      future: query != _lastQuery
          ? ApiService.searchUsers(query)
              .then((r) { _lastQuery = query; _results = r; return r; })
          : Future.value(_results),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.person_off, size: 50, color: Colors.grey),
              SizedBox(height: 12),
              Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
            ]),
          );
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1A73E8).withOpacity(0.15),
                child: Text(u.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
              ),
              title: Text(u.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('ID: ${u.id}  •  ${u.email}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () => close(context, u),
            );
          },
        );
      },
    );
  }
}
