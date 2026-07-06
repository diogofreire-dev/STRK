import 'package:flutter/material.dart';
import '../badges_screen.dart';
import '../theme_provider.dart';

/// Secção "Conquistas" do ecrã de perfil: contador, barra de progresso,
/// grelha de todos os badges e as últimas conquistas desbloqueadas.
/// Extraído de `profile_screen.dart` (era `_ProfileScreenState._buildBadgesSection`,
/// `_buildBadgeGrid` e `_buildRecentBadges`).
class BadgesSection extends StatelessWidget {
  final List<HabitBadge> unlockedBadges;
  final int unlockedCount;
  final int totalCount;
  final List<HabitBadge> allBadges;
  final ThemeProvider theme;

  const BadgesSection({
    super.key,
    required this.unlockedBadges,
    required this.unlockedCount,
    required this.totalCount,
    required this.allBadges,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONQUISTAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary.withValues(alpha: 0.3),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$unlockedCount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: ' / $totalCount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.accent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD60A),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${((unlockedCount / totalCount) * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: totalCount == 0 ? 0 : unlockedCount / totalCount,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
            ),
          ),
          const SizedBox(height: 20),
          _buildBadgeGrid(allBadges, theme),
          if (unlockedBadges.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'ÚLTIMAS CONQUISTAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary.withValues(alpha: 0.2),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildRecentBadges(unlockedBadges),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<HabitBadge> badges, ThemeProvider theme) {
    const iconSize = 36.0;
    const spacing = 8.0;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: badges.map((badge) {
        return Tooltip(
          message: badge.unlocked ? badge.title : '${badge.title} (bloqueado)',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.unlocked
                  ? badge.color.withValues(alpha: 0.18)
                  : theme.textPrimary.withValues(alpha: 0.05),
              border: Border.all(
                color: badge.unlocked
                    ? badge.color.withValues(alpha: 0.5)
                    : theme.textPrimary.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
              size: 16,
              color: badge.unlocked
                  ? badge.color
                  : theme.textPrimary.withValues(alpha: 0.15),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentBadges(List<HabitBadge> unlocked) {
    final recent = unlocked.reversed.take(3).toList();
    return Row(
      children: recent.map((badge) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: badge == recent.last ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: badge.color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(badge.icon, size: 14, color: badge.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badge.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
