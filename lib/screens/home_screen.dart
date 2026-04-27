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
          MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)));
    }
  }

  void _logout() async {
    await AppStorage.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، $_myName 👋'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد محادثات بعد',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('ابحث عن مستخدم لبدء محادثة',
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
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// ========== Search Delegate ==========
class _UserSearchDelegate extends SearchDelegate<ChatUser?> {
  List<ChatUser> _results = [];

  @override
  String get searchFieldLabel => 'ابحث باسم أو ID...';

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('اكتب اسم المستخدم للبحث'));
    }
    return FutureBuilder<List<ChatUser>>(
      future: ApiService.searchUsers(query),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        _results = snap.data ?? [];
        return _buildList(context);
      },
    );
  }

  Widget _buildList(BuildContext context) {
    if (_results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final u = _results[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
            child: Text(u.name[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primaryColor)),
          ),
          title: Text(u.name),
          subtitle: Text(u.email),
          onTap: () => close(context, u),
        );
      },
    );
  }
}
