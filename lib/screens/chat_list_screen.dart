import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch) {
      _searchController.clear();
      context.read<ChatProvider>().clearSearch();
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      context.read<ChatProvider>().clearSearch();
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ChatProvider>().searchUsers(token: token, query: query);
    }
  }

  void _openChat(Chat chat) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.openChat(chat);

    final token = context.read<AuthProvider>().token;
    if (token != null) {
      chatProvider.loadMessages(token: token, userId: chat.userId);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chat: chat,
          token: context.read<AuthProvider>().token ?? '',
        ),
      ),
    );
  }

  void _startChatWithUser(User user) {
    final chat = Chat(userId: user.id, name: user.name);
    _openChat(chat);
    _toggleSearch();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      chatProvider.disconnectWebSocket();
      await authProvider.logout();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // الشريط العلوي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFe2e8f8)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'الرفيق 💬',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFF1e429f),
                      ),
                ),
                const Spacer(),
                _buildIconButton(
                  icon: _showSearch ? Icons.close : Icons.search,
                  onPressed: _toggleSearch,
                ),
                const SizedBox(width: 6),
                _buildIconButton(
                  icon: Icons.logout,
                  onPressed: _logout,
                ),
              ],
            ),
          ),

          // حقل البحث
          if (_showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFe2e8f8)),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    textAlign: TextAlign.right,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم أو ID...',
                      hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94a3b8), size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  // نتائج البحث
                  if (chatProvider.isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  if (chatProvider.searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: chatProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = chatProvider.searchResults[index];
                          return _buildSearchResult(user);
                        },
                      ),
                    ),
                  if (!chatProvider.isSearching &&
                      _searchController.text.isNotEmpty &&
                      chatProvider.searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'لا توجد نتائج',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),

          // حالة الاتصال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            color: chatProvider.wsConnected
                ? const Color(0xFFf0fdf4)
                : const Color(0xFFfef2f2),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chatProvider.wsConnected
                        ? const Color(0xFF22c55e)
                        : const Color(0xFFef4444),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  chatProvider.wsConnected ? 'متصل' : 'غير متصل',
                  style: TextStyle(
                    fontSize: 12,
                    color: chatProvider.wsConnected
                        ? const Color(0xFF166534)
                        : const Color(0xFFef4444),
                  ),
                ),
                const Spacer(),
                Text(
                  'مرحباً، ${authProvider.userName ?? ""} 👋',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),

          // قائمة المحادثات
          Expanded(
            child: chatProvider.isLoadingChats
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.chats.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () {
                          if (authProvider.token != null) {
                            return chatProvider.loadChats(authProvider.token!);
                          }
                          return Future.value();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: chatProvider.chats.length,
                          itemBuilder: (context, index) {
                            return _buildChatItem(chatProvider.chats[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf8faff),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFF64748b)),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildChatItem(Chat chat) {
    final chatProvider = context.watch<ChatProvider>();
    final unread = chatProvider.getUnreadCount(chat.userId);

    return InkWell(
      onTap: () => _openChat(chat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            // الصورة الرمزية
            _buildAvatar(chat.initial),
            const SizedBox(width: 12),
            // معلومات المحادثة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a2340),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // الوقت وعدد غير المقروء
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.formatChatTime(chat.timestamp),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748b)),
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a56db),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(User user) {
    return InkWell(
      onTap: () => _startChatWithUser(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            _buildAvatar(user.initial),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  'ID: ${user.id}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFc7d7ff), Color(0xFFe0e7ff)],
        ),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1a56db),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          const Text(
            'لا توجد محادثات بعد',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748b)),
          ),
          const SizedBox(height: 4),
          Text(
            'ابحث عن شخص لبدء المحادثة',
            style: TextStyle(fontSize: 13, color: const Color(0xFF94a3b8)),
          ),
        ],
      ),
    );
  }
}
