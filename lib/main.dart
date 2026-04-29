import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'screens/auth_screen.dart';
import 'screens/chats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AlrafeegApp());
}

class AlrafeegApp extends StatelessWidget {
  const AlrafeegApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProv, authProv, _) {
          return MaterialApp(
            title: 'الرفيق',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProv.mode,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            // ★ التعديل هنا — ثلاث حالات بدل اثنتين
            home: _buildHome(authProv),
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthProvider authProv) {
    // 1. لسه يتحمّل — اعرض شاشة التحميل
    if (authProv.isLoading) {
      return const _LoadingScreen();
    }
    // 2. مسجّل دخول
    if (authProv.isAuthenticated) {
      return const ChatsScreen();
    }
    // 3. مو مسجّل
    return const AuthScreen();
  }
}

// شاشة تحميل بسيطة
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💬', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFF2F81F7)),
          ],
        ),
      ),
    );
  }
}