import 'package:flutter/material.dart';

import 'theme.dart';

/// Wordmark inspirado na identidade visual da Academia Profissional
/// Prof. Albino de Matos. Não usa o ícone genérico "A"; apresenta a marca
/// textual "academia." como elemento principal.
class AcademiaWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final bool showSchoolText;
  final bool show360;
  final bool inverse;
  final MainAxisAlignment alignment;

  const AcademiaWordmark({
    super.key,
    this.size = 32,
    this.color,
    this.secondaryColor,
    this.showSchoolText = true,
    this.show360 = true,
    this.inverse = false,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? (inverse ? Colors.white : Brand.blue);
    final secondary = secondaryColor ??
        (inverse ? Colors.white.withValues(alpha: 0.76) : Brand.blueDeep);
    final dotColor = inverse ? Colors.white : Brand.blue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'academia',
          style: TextStyle(
            color: primary,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * 0.055,
            height: 0.95,
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            color: dotColor,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: -size * 0.04,
            height: 0.95,
          ),
        ),
        if (show360) ...[
          SizedBox(width: size * 0.18),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size * 0.22,
              vertical: size * 0.075,
            ),
            decoration: BoxDecoration(
              color: inverse
                  ? Colors.white.withValues(alpha: 0.13)
                  : Brand.blue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(size * 0.24),
              border: Border.all(
                color: inverse
                    ? Colors.white.withValues(alpha: 0.22)
                    : Brand.blue.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              '360',
              style: TextStyle(
                color: inverse ? Colors.white : Brand.blueDeep,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
        if (showSchoolText) ...[
          SizedBox(width: size * 0.34),
          Container(
            width: 2,
            height: size * 1.24,
            decoration: BoxDecoration(
              color: secondary.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: size * 0.24),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size * 2.8),
            child: Text(
              'PROFISSIONAL\nPROF. ALBINO\nDE MATOS\nASSOCIAÇÃO',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: secondary,
                fontSize: size * 0.22,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AcademiaCompactMark extends StatelessWidget {
  final double size;
  final bool inverse;
  const AcademiaCompactMark({super.key, this.size = 26, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    return AcademiaWordmark(
      size: size,
      inverse: inverse,
      showSchoolText: false,
      show360: true,
    );
  }
}
