import 'dart:math';
import 'package:flutter/material.dart';

/// Mensagem para quando um streak chega a um número redondo, ou `null`.
String? streakMilestone(String habitName, int streak) {
  switch (streak) {
    case 3:
      return '3 dias de $habitName. Já é um começo a sério.';
    case 7:
      return 'Uma semana inteira de $habitName!';
    case 14:
      return 'Duas semanas de $habitName. Isto já é rotina.';
    case 30:
      return '30 dias de $habitName. Um mês sem falhar!';
    case 50:
      return '50 dias de $habitName. Poucos chegam aqui.';
    case 100:
      return '100 dias de $habitName. Lendário.';
    case 365:
      return 'Um ano inteiro de $habitName.';
  }
  return null;
}

/// Frase do cartão "HOJE" conforme o progresso do dia.
String progressMessage(int done, int total) {
  if (total == 0) return 'Adiciona um hábito para começar.';
  if (done == 0) return 'O dia ainda está todo por fazer.';
  if (done == total) return 'Dia perfeito. Amanhã há mais.';
  if (total - done == 1) return 'Só falta um. Vai lá!';
  if (done * 2 >= total) return 'Mais de metade feito. Bom ritmo.';
  return 'Bom arranque. Continua.';
}

/// Chuva de confettis por cima do ecrã. Dispara sempre que [trigger] muda.
/// Desenhada à mão (CustomPainter) em vez de usar um pacote: são ~80
/// retângulos com gravidade e rotação, não precisa de mais.
class ConfettiOverlay extends StatefulWidget {
  final int trigger;
  final List<Color> colors;
  const ConfettiOverlay({
    super.key,
    required this.trigger,
    required this.colors,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  List<_Piece> _pieces = const [];

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger) _burst();
  }

  void _burst() {
    // Quem pediu ao sistema para reduzir animações não leva com confettis.
    if (MediaQuery.of(context).disableAnimations) return;
    final rnd = Random();
    _pieces = List.generate(80, (_) {
      return _Piece(
        x: rnd.nextDouble(),
        vx: (rnd.nextDouble() - 0.5) * 0.6,
        vy: 0.6 + rnd.nextDouble() * 0.9,
        delay: rnd.nextDouble() * 0.25,
        spin: (rnd.nextDouble() - 0.5) * 12,
        size: 6 + rnd.nextDouble() * 6,
        color: widget.colors[rnd.nextInt(widget.colors.length)],
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => _controller.isAnimating
            ? CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _controller.value),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Piece {
  final double x, vx, vy, delay, spin, size;
  final Color color;
  const _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.delay,
    required this.spin,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0) continue;
      // Começa acima do ecrã e cai com "gravidade" (termo quadrático).
      final dx = (p.x + p.vx * local) * size.width;
      final dy = -20 + (p.vy * local + 0.9 * local * local) * size.height;
      final fade = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * local);
      // Achatar no eixo X imita o confetti a virar no ar.
      canvas.scale(cos(p.spin * local * 2).abs().clamp(0.2, 1.0), 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
