import 'package:flutter/material.dart';

import 'core/brand_logo.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';

export 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Academia360App());
}

class Academia360App extends StatelessWidget {
  const Academia360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppSplashScreen(),
    );
  }
}

/// Splash inicial com branding real da Academia.
/// Mostra a palavra-marca "academia." em vez do ícone genérico com letra A.
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
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 1120), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 460),
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.018), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
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
            colors: [Colors.white, Color(0xFFF2F4FF), Brand.bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -130, right: -110, child: _SplashGlow(size: 330, opacity: 0.12)),
            Positioned(bottom: -160, left: -120, child: _SplashGlow(size: 380, opacity: 0.10)),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 430,
                      constraints: const BoxConstraints(maxWidth: 430),
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.fromLTRB(30, 34, 30, 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Brand.blue.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Brand.blue.withValues(alpha: 0.13),
                            blurRadius: 42,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AcademiaWordmark(size: 35, showSchoolText: true, show360: false),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Brand.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Brand.blue.withValues(alpha: 0.12)),
                            ),
                            child: const Text(
                              'Academia360 · Picagem · Horários · Assiduidade',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Brand.blueDeep,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              width: 180,
                              height: 4,
                              child: LinearProgressIndicator(
                                backgroundColor: Brand.blue.withValues(alpha: 0.11),
                                valueColor: const AlwaysStoppedAnimation<Color>(Brand.blue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'A preparar a plataforma académica',
                            style: TextStyle(
                              color: Brand.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const _SplashGlow({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Brand.blue.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}
