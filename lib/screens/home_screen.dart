import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _myName = await AppStorage.getUserName() ?? '';
    try {
      final chats = await ApiService.getChats();
      setState(() { _chats = chats; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _openSearch() async {
    final user = await showSearch<ChatUser?>(
      context: context,
      delegate: _UserSearchDelegate(),
    );
    if (user != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)))
          .then((_) => _load());
    }
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AppStorage.clear();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('الرفيق',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                )),
            Text('مرحباً، $_myName 👋',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF1A73E8)),
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 50, color: Color(0xFF1A73E8)),
                      ),
                      const SizedBox(height: 16),
                      const Text('لا توجد محادثات بعد',
                          style: TextStyle(color: Colors.grey, fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      const Text('ابحث عن مستخدم لبدء محادثة',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final chat = _chats[i];
                      return ChatTile(
                        name: chat['name'] ?? 'مستخدم',
                        lastMessage: chat['content'] ?? '',
                        timestamp: chat['timestamp'] ?? '',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUser: ChatUser(
                                id: chat['user_id'],
                                name: chat['name'],
                                email: '',
                              ),
                            ),
                          ),
                        ).then((_) => _load()),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearch,
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 6,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ========== Search Delegate — بحث بالاسم والـ ID ==========
class _UserSearchDelegate extends SearchDelegate<ChatUser?> {
  List<ChatUser> _results = [];
  String _lastQuery = '';

  @override
  String get searchFieldLabel => 'ابحث باسم أو ID...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearch(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('ابحث باسم المستخدم أو رقم الـ ID',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return _buildSearch(context);
  }

  Widget _buildSearch(BuildContext context) {
    if (query.length < 1) {
      return const Center(child: Text('اكتب حرفاً واحداً على الأقل'));
    }

    return FutureBuilder<List<ChatUser>>(
      future: query != _lastQuery
          ? ApiService.searchUsers(query).then((r) { _lastQuery = query; _results = r; return r; })
          : Future.value(_results),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}'));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 50, color: Colors.grey),
                SizedBox(height: 12),
                Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
              ],
            ),
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
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w500)),
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
