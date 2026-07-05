import 'package:flutter/material.dart';
import '../../habit.dart';
import '../../theme_provider.dart';

/// Cartão de um hábito na lista do ecrã principal.
///
/// Extraído de `main.dart` (era `_HomeScreenState._buildHabitCard`) para
/// reduzir o tamanho desse ficheiro. O comportamento é exatamente o mesmo;
/// as ações (tocar, manter premido, deslizar para apagar) são passadas por
/// callback em vez de chamarem diretamente o estado do `HomeScreen`.
class HabitCard extends StatelessWidget {
  final Habit habit;
  final ThemeProvider theme;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final VoidCallback onDismissed;

  const HabitCard({
    super.key,
    required this.habit,
    required this.theme,
    required this.onToggle,
    required this.onLongPress,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0x26FF3B30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF3B30),
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: onToggle,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: habit.completedToday
                  ? theme.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.isLight
                      ? theme.accent.withValues(alpha: 0.1)
                      : const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  habit.icon,
                  size: 18,
                  color: habit.completedToday
                      ? theme.accent
                      : theme.textPrimary.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: habit.completedToday
                            ? theme.textPrimary
                            : theme.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${habit.streak} dias',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: habit.completedToday
                                  ? theme.accent
                                  : theme.textPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                          TextSpan(
                            text: ' seguidos',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: habit.completedToday
                      ? theme.accent
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: habit.completedToday
                        ? theme.accent
                        : theme.textPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: habit.completedToday
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
