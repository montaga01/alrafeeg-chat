import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

/// شاشة قائمة المحادثات الرئيسية
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchCtrl = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    // تهيئة ChatProvider عند أول تحميل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      if (auth.token != null && !chat.isWsConnected) {
        chat.init(token: auth.token!, myId: auth.myId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProv = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar مخصص
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 60,
              backgroundColor: isDark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(right: 20, bottom: 14),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الرفيق',
                      style: TextStyle(
                        color: const Color(0xFF2F81F7),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // نقطة حالة WebSocket
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chat.isWsConnected
                            ? const Color(0xFF3FB950)
                            : const Color(0xFF484F58),
                        boxShadow: chat.isWsConnected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3FB950)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // اسم المستخدم
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      auth.myName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8B949E)
                            : const Color(0xFF656D76),
                      ),
                    ),
                  ),
                ),
                // تبديل الوضع
                IconButton(
                  onPressed: () => themeProv.toggleTheme(),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDark),
                      color: const Color(0xFF2F81F7),
                    ),
                  ),
                  tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                ),
                // زر تسجيل الخروج — أيقونة واضحة
                IconButton(
                  onPressed: () => _showLogoutDialog(context, auth, chat),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF85149),
                  ),
                  tooltip: 'تسجيل الخروج',
                ),
              ],
            ),

            // شريط البحث
            SliverToBoxAdapter(
              child: _buildSearchBar(chat, isDark),
            ),

            // نتائج البحث
            if (_showSearchResults && _searchResults.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSearchResults(chat, isDark),
              ),

            // قائمة المحادثات
            chat.isLoadingChats
                ? SliverToBoxAdapter(child: _buildShimmer(isDark))
                : chat.chats.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final c = chat.chats[index];
                            return ChatListItem(
                              chat: ChatModel(
                                userId: c.userId,
                                name: c.name,
                                lastMessage: c.lastMessage,
                                lastMessageTime: c.lastMessageTime,
                                isOnline: chat.isUserOnline(c.userId),
                              ),
                              isActive: chat.currentChat?.userId == c.userId,
                              hasUnread: chat.hasUnread(c.userId),
                              onTap: () => _openChat(context, chat, c),
                            );
                          },
                          childCount: chat.chats.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SEARCH BAR
  // ═══════════════════════════════════════════════════
  Widget _buildSearchBar(ChatProvider chat, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (q) => _onSearch(chat, q),
        decoration: InputDecoration(
          hintText: '🔍 ابحث باسم أو ID...',
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _showSearchResults = false;
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SEARCH RESULTS
  // ═══════════════════════════════════════════════════
  Widget _buildSearchResults(ChatProvider chat, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _searchResults
            .map((u) => UserSearchResult(
                  user: u,
                  isOnline: chat.isUserOnline(u.id),
                  onTap: () => _startChatWith(chat, u),
                ))
            .toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════════════
  Widget _buildShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFF0F2F5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF21262D)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF21262D)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Text(
              '💬',
              style: TextStyle(
                fontSize: 48,
                color: isDark
                    ? const Color(0xFF484F58)
                    : const Color(0xFF8B949E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد محادثات بعد\nابحث عن شخص للبدء',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF484F58)
                    : const Color(0xFF8B949E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  SEARCH
  // ═══════════════════════════════════════════════════
  void _onSearch(ChatProvider chat, String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final users = await chat.searchUsers(query.trim());
      setState(() {
        _searchResults = users;
        _showSearchResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _startChatWith(ChatProvider chat, UserModel user) {
    _searchCtrl.clear();
    _showSearchResults = false;
    _searchResults = [];

    // إنشاء ChatModel من المستخدم
    final newChat = ChatModel(
      userId: user.id,
      name: user.name,
      isOnline: chat.isUserOnline(user.id),
    );

    _openChat(context, chat, newChat);
  }

  void _openChat(BuildContext context, ChatProvider chat, ChatModel c) {
    chat.setCurrentChat(c);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ChatScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  LOGOUT DIALOG
  // ═══════════════════════════════════════════════════
  void _showLogoutDialog(
      BuildContext context, AuthProvider auth, ChatProvider chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFF85149)),
              SizedBox(width: 10),
              Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                chat.disconnect();
                await auth.logout();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF85149),
              ),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );
  }
}
