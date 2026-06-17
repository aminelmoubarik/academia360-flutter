import 'package:flutter/material.dart';

const _brandBlue = Color(0xFF1C29E1);
const _brandInk = Color(0xFF11131A);
const _brandMuted = Color(0xFF667085);
const _brandLine = Color(0xFFE4E7F0);

class SearchBarField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBarField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search, size: 20, color: _brandBlue),
            suffixIcon: const Icon(Icons.tune_outlined, size: 18, color: _brandMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _brandLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _brandLine),
            ),
          ),
        ),
      ),
    );
  }
}

class ResultCount extends StatelessWidget {
  final int count;
  final String noun;
  const ResultCount({super.key, required this.count, required this.noun});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _brandLine),
          ),
          child: Text('$count $noun',
              style: const TextStyle(
                color: _brandMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _brandLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.cloud_off, size: 34, color: Color(0xFFE03131)),
              ),
              const SizedBox(height: 14),
              const Text('Não foi possível carregar os dados',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, color: _brandInk)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _brandMuted, height: 1.35)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF1FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 42, color: _brandBlue),
          ),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _brandMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag({super.key, required this.text, this.color = _brandBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class InitialAvatar extends StatelessWidget {
  final String text;
  final Color color;
  const InitialAvatar({super.key, required this.text, this.color = _brandBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.28)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class AppFeedback {
  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackKind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackKind.info);

  static void _show(BuildContext context, String message, _SnackKind kind) {
    final messenger = ScaffoldMessenger.of(context);
    final (icon, bg) = switch (kind) {
      _SnackKind.success => (Icons.check_circle_outline, const Color(0xFF12A366)),
      _SnackKind.error => (Icons.error_outline, const Color(0xFFE03131)),
      _SnackKind.info => (Icons.info_outline, const Color(0xFF1C29E1)),
    };

    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: kind == _SnackKind.error ? 5 : 3),
        width: _snackWidth(context),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, height: 1.3, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ));
  }

  static double? _snackWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return null;
    return 540;
  }
}

enum _SnackKind { success, error, info }
