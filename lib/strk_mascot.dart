import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOOD ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum MascotMood {
  /// Ecrã inicial, sem interação recente
  idle,

  /// Hábito completado, streak novo
  celebrating,

  /// Hábito por fazer, streak em risco
  encouraging,

  /// Utilizador inativo há vários dias
  sleeping,
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Mascote animada do Strk.
///
/// ```dart
/// StrkMascot(mood: MascotMood.celebrating, size: 120)
/// ```
class StrkMascot extends StatefulWidget {
  final MascotMood mood;

  /// Tamanho do lado do widget (quadrado). Default: 100.
  final double size;

  const StrkMascot({
    super.key,
    required this.mood,
    this.size = 100,
  });

  @override
  State<StrkMascot> createState() => _StrkMascotState();
}

class _StrkMascotState extends State<StrkMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animações individuais extraídas do controller
  late Animation<double> _flicker;   // escala suave do corpo
  late Animation<double> _bounce;    // translação Y (celebração / encorajamento)
  late Animation<double> _blink;     // abertura dos olhos (0 = fechado, 1 = aberto)
  late Animation<double> _sway;      // rotação leve (soneca)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.mood),
    )..repeat(reverse: _reverseFor(widget.mood));

    _buildAnimations();
  }

  @override
  void didUpdateWidget(StrkMascot old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _controller.duration = _durationFor(widget.mood);
      _controller.repeat(reverse: _reverseFor(widget.mood));
      _buildAnimations();
    }
  }

  void _buildAnimations() {
    _flicker = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.97), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.02), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Piscar: maioritariamente aberto, fecha rápido a ~80% da animação
    _blink = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 78),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 10),
    ]).animate(_controller);

    _sway = Tween<double>(begin: -0.08, end: 0.08)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Duration _durationFor(MascotMood m) {
    switch (m) {
      case MascotMood.celebrating:
        return const Duration(milliseconds: 600);
      case MascotMood.encouraging:
        return const Duration(milliseconds: 1000);
      case MascotMood.sleeping:
        return const Duration(milliseconds: 2400);
      case MascotMood.idle:
        return const Duration(milliseconds: 1800);
    }
  }

  bool _reverseFor(MascotMood m) {
    // Todos fazem ping-pong excepto celebração (loop contínuo mais dinâmico)
    return m != MascotMood.celebrating;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          double translateY = 0;
          double rotation = 0;
          double scaleX = 1.0;
          double scaleY = 1.0;

          switch (widget.mood) {
            case MascotMood.idle:
              scaleX = _flicker.value;
              scaleY = 1 / _flicker.value; // conserva área visual

            case MascotMood.celebrating:
              translateY = _bounce.value;
              scaleX = _flicker.value;
              scaleY = _flicker.value;

            case MascotMood.encouraging:
              translateY = _bounce.value * 0.5;
              scaleX = _flicker.value;
              scaleY = _flicker.value;

            case MascotMood.sleeping:
              rotation = _sway.value;
          }

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                child: CustomPaint(
                  painter: _MascotPainter(
                    mood: widget.mood,
                    blinkValue: _blink.value,
                    animValue: _controller.value,
                  ),
                  size: Size(widget.size, widget.size),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final double blinkValue; // 0 = olhos fechados, 1 = abertos
  final double animValue;  // 0..1 progresso da animação (usado para extras)

  const _MascotPainter({
    required this.mood,
    required this.blinkValue,
    required this.animValue,
  });

  // ── Paleta ──────────────────────────────────────────────────────────────────
  static const _orange = Color(0xFFFF6B00);
  static const _amber  = Color(0xFFFFB300);
  static const _yellow = Color(0xFFFFE566);
  static const _ember  = Color(0xFFFF3B00);
  static const _white  = Colors.white;
  static const _dark   = Color(0xFF1A1A1A);
  static const _blue   = Color(0xFF5AC8FA); // usado no sleeping (lágrimas / zzz)

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Referência base: desenho foi concebido para 100×100
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);

    _drawFlame(canvas);
    _drawEyes(canvas);
    _drawMouth(canvas);

    if (mood == MascotMood.celebrating) _drawSparkles(canvas);
    if (mood == MascotMood.sleeping)    _drawZzz(canvas);
    if (mood == MascotMood.encouraging) _drawHearts(canvas);

    canvas.restore();
  }

  // ── Corpo da chama ──────────────────────────────────────────────────────────
  void _drawFlame(Canvas canvas) {
    // Camada exterior (laranja/ember)
    final outer = Path()
      ..moveTo(50, 92)
      ..cubicTo(30, 92, 16, 78, 16, 62)
      ..cubicTo(16, 46, 24, 36, 28, 28)
      ..cubicTo(30, 22, 28, 13, 26, 7)  // ponta histórica do calor
      ..cubicTo(34, 13, 38, 22, 36, 30) // retorno interior esq
      ..cubicTo(38, 18, 40, 8, 38, 2)   // ponta alta esq
      ..cubicTo(48, 10, 52, 24, 50, 36) // arco ponta central
      ..cubicTo(56, 26, 58, 14, 56, 8)  // ponta alta dir
      ..cubicTo(64, 18, 68, 28, 66, 38) // descida dir
      ..cubicTo(70, 30, 72, 20, 70, 12) // mini-ponta dir exterior
      ..cubicTo(78, 22, 84, 36, 84, 52)
      ..cubicTo(84, 72, 70, 92, 50, 92)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_ember, _orange],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawPath(outer, outerPaint);

    // Camada intermédia (âmbar)
    final mid = Path()
      ..moveTo(50, 90)
      ..cubicTo(34, 90, 22, 80, 22, 68)
      ..cubicTo(22, 56, 28, 48, 32, 42)
      ..cubicTo(34, 50, 32, 56, 36, 60)
      ..cubicTo(38, 50, 40, 40, 38, 32)
      ..cubicTo(44, 42, 48, 56, 46, 66)
      ..cubicTo(50, 56, 52, 44, 50, 34)
      ..cubicTo(56, 44, 58, 56, 56, 66)
      ..cubicTo(60, 58, 62, 50, 60, 40)
      ..cubicTo(66, 48, 70, 60, 68, 72)
      ..cubicTo(68, 82, 60, 90, 50, 90)
      ..close();

    final midPaint = Paint()
      ..color = _amber.withValues(alpha: 0.85);
    canvas.drawPath(mid, midPaint);

    // Camada interior (amarelo)
    final inner = Path()
      ..moveTo(50, 86)
      ..cubicTo(40, 86, 32, 80, 32, 70)
      ..cubicTo(32, 62, 36, 58, 38, 56)
      ..cubicTo(38, 62, 40, 66, 44, 68)
      ..cubicTo(46, 62, 48, 56, 46, 50)
      ..cubicTo(50, 58, 52, 64, 52, 70)
      ..cubicTo(56, 66, 58, 60, 58, 54)
      ..cubicTo(60, 58, 64, 64, 64, 72)
      ..cubicTo(64, 80, 58, 86, 50, 86)
      ..close();

    final innerPaint = Paint()
      ..color = _yellow.withValues(alpha: 0.75);
    canvas.drawPath(inner, innerPaint);

    // Brilho topo (reflexo)
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      const Rect.fromLTWH(30, 10, 20, 14),
      glossPaint,
    );
  }

  // ── Olhos ───────────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas) {
    final eyeY = mood == MascotMood.sleeping ? 63.0 : 62.0;

    if (mood == MascotMood.sleeping) {
      _drawSleepingEyes(canvas, eyeY);
      return;
    }

    final eyeOpenH = 9.0 * blinkValue.clamp(0.05, 1.0);

    final whitePaint = Paint()..color = _white;
    final pupilPaint = Paint()..color = _dark;
    final shinePaint = Paint()..color = _white.withValues(alpha: 0.9);

    // Olho esquerdo
    canvas.drawOval(
      Rect.fromCenter(center: Offset(34, eyeY), width: 9, height: eyeOpenH * 2),
      whitePaint,
    );
    // Olho direito
    canvas.drawOval(
      Rect.fromCenter(center: Offset(66, eyeY), width: 9, height: eyeOpenH * 2),
      whitePaint,
    );

    if (blinkValue > 0.1) {
      // Pupilas (deslocadas ligeiramente p/ baixo para dar vida)
      canvas.drawCircle(Offset(34, eyeY + 1), 3.0 * blinkValue, pupilPaint);
      canvas.drawCircle(Offset(66, eyeY + 1), 3.0 * blinkValue, pupilPaint);

      // Brilhos
      canvas.drawCircle(Offset(35.2, eyeY - 1), 1.2, shinePaint);
      canvas.drawCircle(Offset(67.2, eyeY - 1), 1.2, shinePaint);
    }

    // Expressão: sobrancelhas
    _drawBrows(canvas, eyeY);
  }

  void _drawSleepingEyes(Canvas canvas, double eyeY) {
    final paint = Paint()
      ..color = _dark
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Linha curva p/ baixo (olhos fechados a sorrir)
    final leftEye = Path()
      ..moveTo(30, eyeY)
      ..quadraticBezierTo(34, eyeY + 4, 38, eyeY);
    canvas.drawPath(leftEye, paint);

    final rightEye = Path()
      ..moveTo(62, eyeY)
      ..quadraticBezierTo(66, eyeY + 4, 70, eyeY);
    canvas.drawPath(rightEye, paint);
  }

  void _drawBrows(Canvas canvas, double eyeY) {
    final browPaint = Paint()
      ..color = _dark.withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case MascotMood.idle:
        // Sobrancelhas neutras / ligeiramente levantadas
        _arcBrow(canvas, browPaint, 30, eyeY - 8, 38, eyeY - 9, up: true);
        _arcBrow(canvas, browPaint, 62, eyeY - 9, 70, eyeY - 8, up: true);

      case MascotMood.celebrating:
        // Sobrancelhas muito levantadas e arqueadas
        _arcBrow(canvas, browPaint, 29, eyeY - 11, 39, eyeY - 12, up: true);
        _arcBrow(canvas, browPaint, 61, eyeY - 12, 71, eyeY - 11, up: true);

      case MascotMood.encouraging:
        // Sobrancelhas inclinadas para o centro (preocupação amigável)
        _arcBrow(canvas, browPaint, 30, eyeY - 8, 38, eyeY - 11, up: false);
        _arcBrow(canvas, browPaint, 62, eyeY - 11, 70, eyeY - 8, up: false);

      case MascotMood.sleeping:
        break; // sem sobrancelhas ao dormir
    }
  }

  void _arcBrow(
    Canvas canvas,
    Paint paint,
    double x1,
    double y1,
    double x2,
    double y2, {
    required bool up,
  }) {
    final midX = (x1 + x2) / 2;
    final midY = (y1 + y2) / 2 + (up ? -2.5 : 2.0);
    final path = Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(midX, midY, x2, y2);
    canvas.drawPath(path, paint);
  }

  // ── Boca ────────────────────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas) {
    final mouthPaint = Paint()
      ..color = _dark
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const mouthY = 73.0;

    switch (mood) {
      case MascotMood.idle:
        // Sorriso suave
        _smile(canvas, mouthPaint, 36, mouthY, 64, mouthY, depth: 5);

      case MascotMood.celebrating:
        // Sorriso largo com dentes (elipse branca preenchida + arco)
        final teethPaint = Paint()..color = _white;
        canvas.drawOval(
          const Rect.fromLTWH(36, 71, 28, 10),
          teethPaint,
        );
        _smile(canvas, mouthPaint, 36, mouthY, 64, mouthY, depth: 8);
        // rubor nas bochechas
        _blush(canvas);

      case MascotMood.encouraging:
        // Boca ligeiramente aberta (expectante)
        final teethPaint = Paint()..color = _white;
        canvas.drawOval(
          const Rect.fromLTWH(39, 70.5, 22, 7),
          teethPaint,
        );
        _smile(canvas, mouthPaint, 38, mouthY - 1, 62, mouthY - 1, depth: 4);

      case MascotMood.sleeping:
        // Boca relaxada / pequeno sorriso
        _smile(canvas, mouthPaint, 40, mouthY, 60, mouthY, depth: 3);
        // "z z z" já desenhados em _drawZzz
    }
  }

  void _smile(
    Canvas canvas,
    Paint paint,
    double x1,
    double y1,
    double x2,
    double y2, {
    double depth = 5,
  }) {
    final midX = (x1 + x2) / 2;
    final path = Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(midX, y2 + depth, x2, y2);
    canvas.drawPath(path, paint);
  }

  void _blush(Canvas canvas) {
    final blushPaint = Paint()
      ..color = const Color(0xFFFF4444).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(const Offset(24, 72), 8, blushPaint);
    canvas.drawCircle(const Offset(76, 72), 8, blushPaint);
  }

  // ── Extras por mood ─────────────────────────────────────────────────────────

  void _drawSparkles(Canvas canvas) {
    // 3 estrelas em posições fixas, tamanho pulsa com animValue
    final sparkPaint = Paint()
      ..color = _yellow
      ..style = PaintingStyle.fill;

    final positions = [
      const Offset(16, 20),
      const Offset(84, 16),
      const Offset(90, 50),
    ];
    final sizes = [5.0, 4.0, 3.5];

    for (var i = 0; i < positions.length; i++) {
      final phase = (animValue + i * 0.33) % 1.0;
      final s = sizes[i] * (0.6 + 0.4 * math.sin(phase * math.pi * 2));
      _drawStar(canvas, sparkPaint, positions[i], s);
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 8;
      final radius = i.isEven ? r : r * 0.45;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHearts(Canvas canvas) {
    final heartPaint = Paint()
      ..color = const Color(0xFFFF375F).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Dois coraçõezinhos pequenos
    final phase = math.sin(animValue * math.pi * 2);
    _drawHeart(canvas, heartPaint, const Offset(14, 30), 5.0 + phase * 1.0);
    _drawHeart(canvas, heartPaint, const Offset(86, 26), 4.0 + phase * 0.8);
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    // Coração aproximado com Béziers
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 1.2, center.dy - size * 0.6,
      center.dx - size * 2,   center.dy + size * 0.6,
      center.dx,              center.dy + size * 1.8,
    );
    path.cubicTo(
      center.dx + size * 2,   center.dy + size * 0.6,
      center.dx + size * 1.2, center.dy - size * 0.6,
      center.dx,              center.dy + size * 0.3,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawZzz(Canvas canvas) {
    final zPaint = Paint()
      ..color = _blue.withValues(alpha: 0.7 + 0.3 * math.sin(animValue * math.pi * 2))
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Três 'Z' em cascata, tamanhos decrescentes
    _drawZ(canvas, zPaint, const Offset(72, 30), 10);
    _drawZ(canvas, zPaint, const Offset(82, 16), 7);
    _drawZ(canvas, zPaint, const Offset(90, 6),  4.5);
  }

  void _drawZ(Canvas canvas, Paint paint, Offset origin, double size) {
    final path = Path()
      ..moveTo(origin.dx,        origin.dy)
      ..lineTo(origin.dx + size, origin.dy)
      ..lineTo(origin.dx,        origin.dy + size)
      ..lineTo(origin.dx + size, origin.dy + size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.mood != mood ||
      old.blinkValue != blinkValue ||
      old.animValue != animValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: BUBBLE DE TEXTO
// ─────────────────────────────────────────────────────────────────────────────

/// Bolha de mensagem contextual associada ao mood.
class MascotBubble extends StatelessWidget {
  final MascotMood mood;
  final String? customMessage;

  const MascotBubble({super.key, required this.mood, this.customMessage});

  static String defaultMessage(MascotMood mood) {
    switch (mood) {
      case MascotMood.idle:
        return 'Pronto para começar? 🔥';
      case MascotMood.celebrating:
        return 'Incrível! Continua assim! 🎉';
      case MascotMood.encouraging:
        return 'Ainda dá tempo — vai lá! 💪';
      case MascotMood.sleeping:
        return 'Está na hora de voltar... 😴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = customMessage ?? defaultMessage(mood);
    final color = _colorFor(mood);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _colorFor(MascotMood mood) {
    switch (mood) {
      case MascotMood.idle:        return const Color(0xFFFF6B00);
      case MascotMood.celebrating: return const Color(0xFFFFB300);
      case MascotMood.encouraging: return const Color(0xFFFF6B00);
      case MascotMood.sleeping:    return const Color(0xFF5AC8FA);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER COMPOSTO: MASCOTE + BOLHA
// ─────────────────────────────────────────────────────────────────────────────

/// Widget completo: mascote + bolha opcional.
///
/// ```dart
/// StrkMascotCard(
///   mood: MascotMood.celebrating,
///   message: '12 dias seguidos! 🔥',
/// )
/// ```
class StrkMascotCard extends StatelessWidget {
  final MascotMood mood;
  final String? message;
  final double mascotSize;

  const StrkMascotCard({
    super.key,
    required this.mood,
    this.message,
    this.mascotSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StrkMascot(mood: mood, size: mascotSize),
        const SizedBox(height: 12),
        MascotBubble(mood: mood, customMessage: message),
      ],
    );
  }
}
