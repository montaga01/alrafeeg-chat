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
      title: 'الرافع',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _Splash(),
    );
  }
}

/// شاشة البداية: تتحقق من التوكن وتوجّه للشاشة الصحيحة
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AppStorage.getToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => token != null ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
