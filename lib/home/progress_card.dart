import 'package:flutter/material.dart';
import '../../theme_provider.dart';
import 'celebrations.dart';
import '../../mascot.dart';

/// Cartão "HOJE" com o progresso do dia (quantos hábitos concluídos de
/// quantos no total). A barra, o número e a percentagem animam quando o
/// progresso muda, e a frase de baixo acompanha o dia.
class ProgressCard extends StatelessWidget {
  final ThemeProvider theme;
  final int completedCount;
  final int totalCount;

  const ProgressCard({
    super.key,
    required this.theme,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final accent = theme.accent;
    final perfect = totalCount > 0 && completedCount == totalCount;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.9),
            accent,
            accent.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        // No dia perfeito o cartão "brilha" na própria cor.
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: perfect ? 0.45 : 0.0),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOJE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0x80FFFFFF),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: RichText(
                  key: ValueKey('$completedCount/$totalCount'),
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$completedCount',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: '/$totalCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0x80FFFFFF),
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // A chama acompanha o dia: apagada sem nada feito, feliz a
              // meio e em festa no dia perfeito. O círculo escuro dá-lhe
              // contraste em cima do laranja do cartão.
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.16),
                ),
                child: StrkMascot(
                  mood: MascotMood.forProgress(completedCount, totalCount),
                  size: 78,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            // A barra desliza até ao valor novo em vez de saltar.
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // Por omissão o AnimatedSwitcher centra o texto.
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    progressMessage(completedCount, totalCount),
                    key: ValueKey(progressMessage(completedCount, totalCount)),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xCCFFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xCCFFFFFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
