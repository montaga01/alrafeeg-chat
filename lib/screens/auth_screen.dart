import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../config/app_config.dart';

/// شاشة تسجيل الدخول والتسجيل مع تصميم إبداعي حيوي
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();
  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0D1117),
                      const Color(0xFF161B22),
                      const Color(0xFF0D1117),
                    ]
                  : [
                      const Color(0xFFF6F8FA),
                      const Color(0xFFFFFFFF),
                      const Color(0xFFF6F8FA),
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // اللوغو
                      _buildLogo(isDark),
                      const SizedBox(height: 24),

                      // صندوق الدخول/التسجيل
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161B22)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF30363D)
                                : const Color(0xFFD0D7DE),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // التبويبات
                            _buildTabs(isDark),
                            // المحتوى
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildLoginForm(auth, isDark),
                                  _buildRegisterForm(auth, isDark),
                                ],
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
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  LOGO
  // ═══════════════════════════════════════════════════
  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F81F7), Color(0xFF1F6FEB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F81F7).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '💬',
              style: TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appSubtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  TABS
  // ═══════════════════════════════════════════════════
  Widget _buildTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F81F7), Color(0xFF1F6FEB)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F81F7).withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'دخول'),
          Tab(text: 'تسجيل'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  LOGIN FORM
  // ═══════════════════════════════════════════════════
  Widget _buildLoginForm(AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            // حقل البريد
            TextFormField(
              controller: _loginEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@mail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // حقل كلمة المرور
            TextFormField(
              controller: _loginPassCtrl,
              obscureText: _obscureLoginPass,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPass
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPass = !_obscureLoginPass;
                    });
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                return null;
              },
              onFieldSubmitted: (_) => _doLogin(auth),
            ),
            const SizedBox(height: 10),

            // خطأ
            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF85149).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFF85149).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFF85149), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                          color: Color(0xFFF85149),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // زر الدخول
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => _doLogin(auth),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('دخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  REGISTER FORM
  // ═══════════════════════════════════════════════════
  Widget _buildRegisterForm(AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _regFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _regNameCtrl,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                hintText: 'اسمك الكريم',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل اسمك';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _regEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@mail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _regPassCtrl,
              obscureText: _obscureRegPass,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                hintText: '6 أحرف على الأقل',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegPass
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureRegPass = !_obscureRegPass;
                    });
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return '6 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 10),

            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF85149).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFF85149).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFF85149), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                          color: Color(0xFFF85149),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => _doRegister(auth),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('إنشاء حساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════

  Future<void> _doLogin(AuthProvider auth) async {
    if (!_loginFormKey.currentState!.validate()) return;
    auth.clearError();
    final success = await auth.login(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPassCtrl.text,
    );
    if (!success && mounted) {
      // الخطأ ظاهر بالفعل
    }
  }

  Future<void> _doRegister(AuthProvider auth) async {
    if (!_regFormKey.currentState!.validate()) return;
    auth.clearError();
    await auth.register(
      name: _regNameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text,
    );
  }
}
