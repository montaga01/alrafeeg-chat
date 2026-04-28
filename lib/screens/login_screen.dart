import 'dart:math';
import 'package:flutter/material.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

// ══════════════════════════════════════════════════════════════
//  خلفية نجوم متحركة
// ══════════════════════════════════════════════════════════════
class _FloatingDot {
  double x, y, size, speed, opacity, angle;
  _FloatingDot({required this.x, required this.y, required this.size,
      required this.speed, required this.opacity, required this.angle});
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    for (int i = 0; i < 22; i++) {
      _dots.add(_FloatingDot(
        x: _rnd.nextDouble(), y: _rnd.nextDouble(),
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
      final paint = Paint()..color = const Color(0xFF1A73E8).withOpacity(d.opacity);
      final cx = dx * size.width;
      final cy = dy * size.height;
      final r  = d.size / 2;
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final a  = i * pi / 3 + t * pi;
        final br = i.isEven ? r : r * 0.5;
        if (i == 0) path.moveTo(cx + br * cos(a), cy + br * sin(a));
        else        path.lineTo(cx + br * cos(a), cy + br * sin(a));
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => true;
}

// ══════════════════════════════════════════════════════════════
//  تأثير دوامة "جارٍ التحميل" داخل الزر
// ══════════════════════════════════════════════════════════════
class _LoadingRipplePainter extends CustomPainter {
  final double t;
  _LoadingRipplePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 0; i < 3; i++) {
      final phase  = (t + i / 3) % 1.0;
      final radius = phase * (size.width * 0.48);
      final opacity = (1 - phase) * 0.45;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    // نجمة تدور في المنتصف
    final paint = Paint()..color = Colors.white.withOpacity(0.9);
    final r = 8.0;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a  = i * 2 * pi / 5 + t * 2 * pi;
      final br = i.isEven ? r : r * 0.45;
      if (i == 0) path.moveTo(cx + br * cos(a), cy + br * sin(a));
      else        path.lineTo(cx + br * cos(a), cy + br * sin(a));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LoadingRipplePainter old) => old.t != t;
}

class _LoadingButton extends StatefulWidget {
  const _LoadingButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<_LoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _rippleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.onPressed == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2979FF), Color(0xFF0D47A1)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(0.5),
            blurRadius: isLoading ? 28 : 18,
            offset: const Offset(0, 6),
            spreadRadius: isLoading ? 3 : 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (_, __) => SizedBox(
                  width: 54, height: 30,
                  child: CustomPaint(painter: _LoadingRipplePainter(_rippleCtrl.value)),
                ),
              )
            : widget.child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  شاشة تسجيل الدخول
// ══════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading      = false;
  bool _showPassword = false;
  bool _showSuggestions = false;
  String? _error;
  List<String> _emailHistory = [];

  late AnimationController _btnCtrl;
  late Animation<double>   _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
    _loadHistory();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus && _emailHistory.isNotEmpty) {
        setState(() => _showSuggestions = true);
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  Future<void> _loadHistory() async {
    final h = await AppStorage.getEmailHistory();
    if (mounted) setState(() => _emailHistory = h);
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
    setState(() { _loading = true; _error = null; _showSuggestions = false; });
    try {
      final data = await ApiService.login(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await AppStorage.saveSession(
        token:  data['token'],
        userId: data['user']['id'],
        name:   data['user']['name'],
        email:  data['user']['email'],
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // خلفية متدرجة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFEEF4FF), Color(0xFFF5F7FA), Color(0xFFE8F0FE)],
              ),
            ),
          ),
          const _AnimatedBackground(),

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
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.4),
                              blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.chat_rounded, color: Colors.white, size: 46),
                    ),
                    const SizedBox(height: 20),
                    const Text('الرفيق',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E), letterSpacing: 1)),
                    const SizedBox(height: 6),
                    const Text('سجّل دخولك للمتابعة',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 36),

                    // ── حقل الإيميل مع اقتراحات ─────────────────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TextField(
                          controller:      _emailCtrl,
                          focusNode:       _emailFocus,
                          keyboardType:    TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_emailHistory.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),

                        // قائمة الاقتراحات
                        if (_showSuggestions && _emailHistory.isNotEmpty)
                          Positioned(
                            top: 58, left: 0, right: 0,
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _emailHistory.map((email) {
                                    // فلتر بما يكتبه المستخدم
                                    final q = _emailCtrl.text.trim().toLowerCase();
                                    if (q.isNotEmpty && !email.toLowerCase().contains(q)) {
                                      return const SizedBox.shrink();
                                    }
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.history,
                                          size: 18, color: Color(0xFF1A73E8)),
                                      title: Text(email,
                                          style: const TextStyle(fontSize: 14)),
                                      onTap: () {
                                        _emailCtrl.text = email;
                                        setState(() => _showSuggestions = false);
                                        FocusScope.of(context).requestFocus(_passwordFocus);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // حقل كلمة المرور
                    TextField(
                      controller:      _passwordCtrl,
                      focusNode:       _passwordFocus,
                      obscureText:     !_showPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted:     (_) => _loading ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
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

                    // ── زر الدخول مع تأثير التحميل الإبداعي ─────────────────
                    ScaleTransition(
                      scale: _btnScale,
                      child: SizedBox(
                        width: double.infinity, height: 54,
                        child: _LoadingButton(
                          onPressed: _loading ? null : _login,
                          child: const Text('تسجيل الدخول',
                              style: TextStyle(fontSize: 17, color: Colors.white,
                                  fontWeight: FontWeight.w600)),
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
                                begin: const Offset(1, 0), end: Offset.zero).animate(a),
                            child: child,
                          ),
                        ),
                      ),
                      child: const Text('ليس لديك حساب؟ سجّل الآن',
                          style: TextStyle(color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.w500)),
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
