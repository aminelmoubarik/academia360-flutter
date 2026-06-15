import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const Academia360App());

class Brand {
  static const Color blue = Color(0xFF1929E9);
  static const Color blueLight = Color(0xFF4A5CF0);
  static const Color ink = Color(0xFF1A1A2E);
  static const Color bg = Color(0xFFF5F6FA);
  static const Color ok = Color(0xFF0CA678);
  static const Color warn = Color(0xFFE8590C);
  static const Color danger = Color(0xFFE03131);
}

class Academia360App extends StatelessWidget {
  const Academia360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Brand.blue)
            .copyWith(primary: Brand.blue, secondary: Brand.blue),
        scaffoldBackgroundColor: Brand.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Brand.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Brand.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Brand.blue, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
