import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Introduza o email e a palavra-passe.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _error = 'Email ou palavra-passe incorretos.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro de ligação. Confirme se o backend está ativo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.bg,
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        return Stack(
          children: [
            const Positioned.fill(child: _SoftBackground()),
            Row(
              children: [
                if (isWide)
                  const Expanded(
                    flex: 5,
                    child: _BrandHero(),
                  ),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _LoginCard(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          error: _error,
                          isLoading: _isLoading,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          onLogin: _login,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Brand.blueSoft.withValues(alpha: 0.8), Brand.bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: Brand.heroGradient,
        boxShadow: [
          BoxShadow(
            color: Brand.blue.withValues(alpha: 0.24),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -120, right: -100, child: _Glow(size: 320, opacity: 0.18)),
          Positioned(bottom: -150, left: -120, child: _Glow(size: 360, opacity: 0.14)),
          Positioned(
            right: 38,
            top: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Text(
                'PT · Academia360',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'academia',
                        style: TextStyle(
                          color: Brand.blue,
                          fontSize: 35,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      Text('.', style: TextStyle(color: Brand.blue, fontSize: 35, fontWeight: FontWeight.w900)),
                      SizedBox(width: 8),
                      Text(
                        '360',
                        style: TextStyle(
                          color: Brand.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PROFISSIONAL PROF. ALBINO DE MATOS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 58),
                const Text(
                  'Gestão académica\nclara, rápida e integrada.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Horários automáticos, assiduidade e configuração escolar numa plataforma inspirada na identidade visual da Academia.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 42),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _Pill(icon: Icons.nfc, label: 'NFC / QR'),
                    _Pill(icon: Icons.auto_awesome, label: 'Horários'),
                    _Pill(icon: Icons.analytics_outlined, label: 'Relatórios'),
                    _Pill(icon: Icons.admin_panel_settings_outlined, label: 'Administração'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? error;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.error,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Brand.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Brand.blueSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'academia360',
                style: TextStyle(color: Brand.blue, fontWeight: FontWeight.w900, letterSpacing: -0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bem-vindo de volta',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              color: Brand.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inicie sessão para continuar na plataforma.',
            style: TextStyle(fontSize: 14, color: Brand.muted),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => onLogin(),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Palavra-passe',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: obscurePassword ? 'Mostrar' : 'Ocultar',
                onPressed: onTogglePassword,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Brand.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Iniciar sessão'),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Academia360 · Projeto Erasmus+',
              style: TextStyle(fontSize: 12, color: Brand.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final double opacity;
  const _Glow({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
