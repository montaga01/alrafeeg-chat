import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading      = false;
  bool _showPassword = false;
  String? _error;

  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _btnCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم التسجيل بنجاح! سجّل دخولك الآن'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF4FF), Color(0xFFF5F7FA), Color(0xFFE8F0FE)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar مخصص
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A237E)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? size.width * 0.3 : 28,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          // لوغو صغير
                          Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A73E8).withOpacity(0.35),
                                  blurRadius: 16, offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text('الرفيق',
                              style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              )),
                          const SizedBox(height: 28),

                          // الاسم — انتر → إيميل
                          TextField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_emailFocus),
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // الإيميل — انتر → كلمة المرور
                          TextField(
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_passwordFocus),
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // كلمة المرور مع إظهار — انتر يسجّل
                          TextField(
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loading ? null : _register(),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور (6 أحرف على الأقل)',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_error!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 13))),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // زر التسجيل — فسفوري
                          ScaleTransition(
                            scale: _btnScale,
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2979FF).withOpacity(0.5),
                                      blurRadius: 18, offset: const Offset(0, 6),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text('إنشاء الحساب',
                                          style: TextStyle(
                                            fontSize: 17, color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          )),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
