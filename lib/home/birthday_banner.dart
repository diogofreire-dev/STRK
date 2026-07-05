import 'package:flutter/material.dart';
import '../../theme_provider.dart';

/// Banner de aniversário mostrado no topo do ecrã principal. Extraído de
/// `main.dart` (era `_HomeScreenState._buildBirthdayBanner`).
class BirthdayBanner extends StatelessWidget {
  final ThemeProvider theme;
  final String? displayName;

  const BirthdayBanner({super.key, required this.theme, this.displayName});

  @override
  Widget build(BuildContext context) {
    final name = displayName?.split(' ').first ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBF5AF2).withValues(alpha: 0.2),
            const Color(0xFFFF6B00).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBF5AF2).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Text('🥳', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feliz aniversário${name.isNotEmpty ? ', $name' : ''}!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  'Que os teus hábitos te levem longe este ano 🔥',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
