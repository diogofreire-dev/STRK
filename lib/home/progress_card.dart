import 'package:flutter/material.dart';
import '../../theme_provider.dart';

/// Cartão "HOJE" com o progresso do dia (quantos hábitos concluídos de
/// quantos no total). Extraído de `main.dart`
/// (era `_HomeScreenState._buildProgressCard`).
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
    return Container(
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
              RichText(
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
              Text(
                '${(progress * 100).round()}% feito',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xCCFFFFFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pequenos passos todos os dias fazem a diferença ✨',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xCCFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
