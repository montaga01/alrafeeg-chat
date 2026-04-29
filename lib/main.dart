import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'screens/auth_screen.dart';
import 'screens/chats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تثبيت الاتجاه
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // شريط الحالة الشفاف
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
            home: authProv.isAuthenticated
                ? const ChatsScreen()
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
