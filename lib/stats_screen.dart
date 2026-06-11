import 'package:flutter/material.dart';
import 'habit.dart';
import 'theme_provider.dart';

class StatsScreen extends StatelessWidget {
  final List<Habit> habits;
  const StatsScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final completed = habits.where((h) => h.completedToday).length;
    final total = habits.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final avgStreak = habits.isEmpty
        ? 0.0
        : habits.map((h) => h.streak).reduce((a, b) => a + b) / habits.length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildTodayCard(completed, total, progress, theme),
              const SizedBox(height: 16),
              _buildStatsGrid(bestStreak, avgStreak, theme),
              const SizedBox(height: 24),
              _sectionLabel('Hábitos por streak', theme),
              const SizedBox(height: 12),
              _buildStreakList(theme),
              const SizedBox(height: 24),
              _sectionLabel('Progresso de hoje', theme),
              const SizedBox(height: 12),
              _buildHabitBars(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ThemeProvider theme) => Text(
    label.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: theme.textHint,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildTodayCard(
    int completed,
    int total,
    double progress,
    ThemeProvider theme,
  ) {
    final accent = theme.accent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent,
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
                      text: '$completed',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0x80FFFFFF),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'concluído',
                    style: TextStyle(fontSize: 12, color: Color(0x80FFFFFF)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    int bestStreak,
    double avgStreak,
    ThemeProvider theme,
  ) => Row(
    children: [
      Expanded(
        child: _statCard(
          'Melhor streak',
          '$bestStreak',
          'dias',
          Icons.local_fire_department_rounded,
          theme.accent,
          theme,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _statCard(
          'Média de streak',
          avgStreak.toStringAsFixed(1),
          'dias',
          Icons.trending_up_rounded,
          const Color(0xFFFFB300),
          theme,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _statCard(
          'Total hábitos',
          '${habits.length}',
          'hábitos',
          Icons.checklist_rounded,
          const Color(0xFF64D2FF),
          theme,
        ),
      ),
    ],
  );

  Widget _statCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
    ThemeProvider theme,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
            letterSpacing: -1,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: theme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildStreakList(ThemeProvider theme) {
    if (habits.isEmpty) return _empty('Ainda não tens hábitos.', theme);
    final sorted = [...habits]..sort((a, b) => b.streak.compareTo(a.streak));
    final maxStreak = sorted.first.streak;
    return Column(
      children: sorted.map((habit) {
        final pct = maxStreak == 0 ? 0.0 : habit.streak / maxStreak;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(habit.icon, size: 16, color: theme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          '${habit.streak} dias',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: theme.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitBars(ThemeProvider theme) {
    if (habits.isEmpty) return _empty('Ainda não tens hábitos.', theme);
    return Column(
      children: habits
          .map(
            (habit) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: habit.completedToday
                      ? theme.accent.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    habit.completedToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: habit.completedToday ? theme.accent : theme.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: habit.completedToday
                            ? theme.textPrimary
                            : theme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    habit.completedToday ? 'Feito ✓' : 'Por fazer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: habit.completedToday
                          ? theme.accent
                          : theme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _empty(String msg, ThemeProvider theme) => Center(
    child: Text(msg, style: TextStyle(color: theme.textHint, fontSize: 14)),
  );
}
