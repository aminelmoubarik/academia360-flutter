import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const Academia360App());

/// Paleta inspirada na página pública da Academia:
/// azul cobalto do logótipo, muito branco, texto escuro e cartões arredondados.
class Brand {
  static const Color blue = Color(0xFF1C29E1);
  static const Color blueDeep = Color(0xFF111B9F);
  static const Color blueLight = Color(0xFF6370FF);
  static const Color blueSoft = Color(0xFFEFF1FF);
  static const Color ink = Color(0xFF11131A);
  static const Color muted = Color(0xFF667085);
  static const Color bg = Color(0xFFF7F8FC);
  static const Color line = Color(0xFFE4E7F0);
  static const Color ok = Color(0xFF12A366);
  static const Color warn = Color(0xFFE8590C);
  static const Color danger = Color(0xFFE03131);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [blue, blueDeep, blueLight],
    stops: [0.0, 0.58, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Brand.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: Brand.blue,
          secondary: Brand.blueLight,
          surface: Colors.white,
          error: Brand.danger,
        ),
        scaffoldBackgroundColor: Brand.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Brand.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Brand.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: Brand.ink),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Brand.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Brand.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Brand.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _AcademiaPageTransitionBuilder(),
            TargetPlatform.iOS: _AcademiaPageTransitionBuilder(),
            TargetPlatform.macOS: _AcademiaPageTransitionBuilder(),
            TargetPlatform.windows: _AcademiaPageTransitionBuilder(),
            TargetPlatform.linux: _AcademiaPageTransitionBuilder(),
            TargetPlatform.fuchsia: _AcademiaPageTransitionBuilder(),
          },
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelStyle: const TextStyle(color: Brand.muted),
          hintStyle: TextStyle(color: Brand.muted.withValues(alpha: 0.65)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Brand.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Brand.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Brand.blue, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Brand.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Brand.danger, width: 1.8),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Brand.line),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      home: const AppSplashScreen(),
    );
  }
}


class _AcademiaPageTransitionBuilder extends PageTransitionsBuilder {
  const _AcademiaPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.018, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Brand.blueSoft, Color(0xFFF7F8FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: Brand.heroGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Brand.blue.withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'a.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Academia360',
                    style: TextStyle(
                      color: Brand.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A preparar a plataforma académica',
                    style: TextStyle(
                      color: Brand.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
