import 'dart:math';
import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

// ========== خلفية متحركة ==========
class _FloatingDot {
  double x, y, size, speed, opacity, angle;
  _FloatingDot({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.angle,
  });
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_FloatingDot> _dots = [];
  final Random _rnd = Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    for (int i = 0; i < 22; i++) {
      _dots.add(_FloatingDot(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        size: _rnd.nextDouble() * 8 + 4,
        speed: _rnd.nextDouble() * 0.15 + 0.03,
        opacity: _rnd.nextDouble() * 0.15 + 0.03,
        angle: _rnd.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _DotsPainter(_dots, _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final List<_FloatingDot> dots;
  final double t;
  _DotsPainter(this.dots, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final dy = (d.y + t * d.speed) % 1.0;
      final dx = d.x + sin(t * 2 * pi + d.angle) * 0.015;
      final paint = Paint()
        ..color = const Color(0xFF1A73E8).withOpacity(d.opacity);
      // رسم نجمة صغيرة بدل نقطة
      final cx = dx * size.width;
      final cy = dy * size.height;
      final r = d.size / 2;
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final a = i * pi / 3 + t * pi;
        final br = i.isEven ? r : r * 0.5;
        if (i == 0) path.moveTo(cx + br * cos(a), cy + br * sin(a));
        else path.lineTo(cx + br * cos(a), cy + br * sin(a));
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => true;
}

// ========== شاشة تسجيل الدخول ==========
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _emailFocus    = FocusNode();
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await AppStorage.saveSession(
        token: data['token'],
        userId: data['user']['id'],
        name: data['user']['name'],
        email: data['user']['email'],
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
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
          // خلفية متدرجة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF4FF), Color(0xFFF5F7FA), Color(0xFFE8F0FE)],
              ),
            ),
          ),

          // أشكال إسلامية متحركة
          const _AnimatedBackground(),

          // المحتوى — في النص دايماً
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.3 : 28,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // لوغو
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A73E8).withOpacity(0.4),
                            blurRadius: 20, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chat_rounded, color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 20),

                    const Text('الرفيق',
                        style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E), letterSpacing: 1,
                        )),
                    const SizedBox(height: 6),
                    const Text('سجّل دخولك للمتابعة',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 36),

                    // حقل الإيميل — انتر ينتقل للباسورد
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

                    // حقل كلمة المرور مع إظهار/إخفاء — انتر يسجّل دخول
                    TextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
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

                    // رسالة الخطأ
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
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // زر تسجيل الدخول — فسفوري مع توهج
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
                            onPressed: _loading ? null : _login,
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
                                : const Text('تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 17, color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) => const RegisterScreen(),
                          transitionsBuilder: (_, a, __, child) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0), end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                      ),
                      child: const Text(
                        'ليس لديك حساب؟ سجّل الآن',
                        style: TextStyle(
                          color: Color(0xFF1A73E8), fontWeight: FontWeight.w500,
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
    );
  }
}
