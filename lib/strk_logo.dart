import 'package:flutter/material.dart';
import 'theme_provider.dart';

/// Logo STRK dinâmica — barras e texto acompanham o accent do tema.
/// Usa CustomPainter para não depender de SVG externo.
class StrkLogo extends StatelessWidget {
  final double height;

  const StrkLogo({super.key, this.height = 26});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final accent = theme.accent;
    final text = theme.textPrimary;

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LogoPainter(accent: accent, text: text),
        size: Size(height * 3.0, height),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color accent;
  final Color text;

  _LogoPainter({required this.accent, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final unit = h / 40; // escala baseada na viewBox original 120x40

    final barPaint = Paint()..color = text.withValues(alpha: 0.7);
    final accentPaint = Paint()..color = accent;

    final radius = Radius.circular(2 * unit);

    // Barra 1 — curta
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * unit, 20 * unit, 8 * unit, 16 * unit),
        radius,
      ),
      barPaint,
    );

    // Barra 2 — média
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * unit, 12 * unit, 8 * unit, 24 * unit),
        radius,
      ),
      barPaint,
    );

    // Barra 3 — alta (accent)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(32 * unit, 4 * unit, 8 * unit, 32 * unit),
        radius,
      ),
      accentPaint,
    );

    // Texto "strk"
    final tp = TextPainter(
      text: TextSpan(
        text: 'strk',
        style: TextStyle(
          color: text,
          fontSize: 26 * unit,
          fontWeight: FontWeight.w800,
          fontFamily: 'SF Pro Display',
          letterSpacing: -1 * unit,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(56 * unit, 28 * unit - tp.height));
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.accent != accent || old.text != text;
}
