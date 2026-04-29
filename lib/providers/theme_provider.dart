import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void toggleTheme() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2F81F7),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2F81F7),
          secondary: Color(0xFF1F6FEB),
          surface: Color(0xFF161B22),
          error: Color(0xFFF85149),
          onPrimary: Colors.white,
          onSurface: Color(0xFFE6EDF3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFFE6EDF3)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B22),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF21262D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF30363D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2F81F7)),
          ),
          hintStyle: const TextStyle(color: Color(0xFF484F58)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F81F7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF30363D),
          thickness: 1,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF484F58),
            fontSize: 12,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161B22),
          selectedItemColor: Color(0xFF2F81F7),
          unselectedItemColor: Color(0xFF484F58),
        ),
      );

  // ═══════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2F81F7),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2F81F7),
          secondary: Color(0xFF1F6FEB),
          surface: Color(0xFFFFFFFF),
          error: Color(0xFFCF222E),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1F2328),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2328),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1F2328)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: const Color(0xFFD0D7DE)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF6F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2F81F7)),
          ),
          hintStyle: const TextStyle(color: Color(0xFF656D76)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F81F7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFD0D7DE),
          thickness: 1,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF1F2328),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF1F2328),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF1F2328),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF656D76),
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 12,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          selectedItemColor: Color(0xFF2F81F7),
          unselectedItemColor: Color(0xFF8B949E),
        ),
      );
}
