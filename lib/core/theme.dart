import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Academia360 — sistema de design
///
/// Cores de marca (acento) que funcionam em modo claro e escuro, mais um
/// conjunto de *tokens semânticos* (superfície, fundo, texto, linha) que se
/// adaptam ao brilho atual. Os ecrãs leem `AppColors.of(context)` para nunca
/// ficarem presos ao branco.
/// ---------------------------------------------------------------------------

class Brand {
  // Azul cobalto do logótipo — acento principal.
  static const Color blue = Color(0xFF2B3AF0);
  static const Color blueDeep = Color(0xFF111B9F);
  static const Color blueLight = Color(0xFF6370FF);

  // Acentos secundários para módulos.
  static const Color teal = Color(0xFF0CA6A6);
  static const Color green = Color(0xFF12A366);
  static const Color orange = Color(0xFFF0780A);
  static const Color violet = Color(0xFF7C4DFF);
  static const Color pink = Color(0xFFE8458B);
  static const Color amber = Color(0xFFE8A100);

  static const Color ok = Color(0xFF12A366);
  static const Color warn = Color(0xFFE8590C);
  static const Color danger = Color(0xFFF0414E);

  // --- Tokens de compatibilidade (fallback do modo claro) ---
  // Os ecrãs core usam AppColors.of(context); estes existem para os restantes.
  static const Color bg = Color(0xFFF4F6FB);
  static const Color ink = Color(0xFF11131A);
  static const Color muted = Color(0xFF667085);
  static const Color line = Color(0xFFE4E7F0);
  static const Color blueSoft = Color(0xFFEFF1FF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [blue, blueDeep, blueLight],
    stops: [0.0, 0.58, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente suave por acento (para cabeçalhos e ícones).
  static LinearGradient accent(Color c) => LinearGradient(
        colors: [c, Color.lerp(c, const Color(0xFF000000), 0.28)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Tokens semânticos dependentes do tema.
class AppColors {
  final Color bg; // fundo do ecrã
  final Color bgSubtle; // fundo ligeiramente contrastante
  final Color surface; // cartões, diálogos
  final Color surfaceAlt; // campos, chips
  final Color line; // bordas
  final Color ink; // texto principal
  final Color muted; // texto secundário
  final Color faint; // texto terciário / placeholders
  final bool isDark;

  const AppColors({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.isDark,
  });

  static const AppColors light = AppColors(
    bg: Color(0xFFF4F6FB),
    bgSubtle: Color(0xFFEDEFF7),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF7F8FC),
    line: Color(0xFFE4E7F0),
    ink: Color(0xFF11131A),
    muted: Color(0xFF667085),
    faint: Color(0xFF98A2B3),
    isDark: false,
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF0B0D14),
    bgSubtle: Color(0xFF11141F),
    surface: Color(0xFF161A26),
    surfaceAlt: Color(0xFF1D2230),
    line: Color(0xFF2A3142),
    ink: Color(0xFFF1F3F9),
    muted: Color(0xFF98A2B3),
    faint: Color(0xFF667085),
    isDark: true,
  );

  /// Lê os tokens do tema atual.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.blue,
      brightness: brightness,
    ).copyWith(
      primary: Brand.blue,
      secondary: Brand.blueLight,
      surface: c.surface,
      error: Brand.danger,
      onSurface: c.ink,
    );

    OutlineInputBorder border(Color col, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: col, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.surface,
      dividerColor: c.line,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: c.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Brand.blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        labelStyle: TextStyle(color: c.muted),
        hintStyle: TextStyle(color: c.faint),
        helperStyle: TextStyle(color: c.faint, fontSize: 11.5),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        border: border(c.line),
        enabledBorder: border(c.line),
        focusedBorder: border(Brand.blue, 1.8),
        errorBorder: border(Brand.danger),
        focusedErrorBorder: border(Brand.danger, 1.8),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: c.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Brand.blue : c.faint.withValues(alpha: 0.5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.blue),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
