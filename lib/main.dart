import 'package:flutter/material.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlrafeegApp());
}

class AlrafeegApp extends StatelessWidget {
  const AlrafeegApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الرفيق',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _Splash(),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    _check();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final token = await AppStorage.getToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            token != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF4FF), Color(0xFFE8F0FE)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.4),
                          blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 20),
                const Text('الرفيق',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E), letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
