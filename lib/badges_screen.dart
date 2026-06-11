import 'package:flutter/material.dart';
import 'habit.dart';
import 'theme_provider.dart';

class HabitBadge {
  final String id, title, description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  const HabitBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

List<HabitBadge> computeBadges(List<Habit> habits) {
  final best = habits.isEmpty
      ? 0
      : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
  final total = habits.length;
  final completedCount = habits.where((h) => h.completedToday).length;
  final allDone = total > 0 && completedCount == total;
  final totalStreak = habits.isEmpty
      ? 0
      : habits.map((h) => h.streak).reduce((a, b) => a + b);
  final withReminder = habits.where((h) => h.reminderEnabled).length;

  return [
    HabitBadge(
      id: 'first_habit',
      title: 'Primeiro Passo',
      description: 'Criaste o teu primeiro hábito',
      icon: Icons.flag_rounded,
      color: const Color(0xFFFF6B00),
      unlocked: total >= 1,
    ),
    HabitBadge(
      id: 'three_habits',
      title: 'Dedicado',
      description: 'Tens 3 hábitos ativos',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFBF5AF2),
      unlocked: total >= 3,
    ),
    HabitBadge(
      id: 'five_habits',
      title: 'Colecionador',
      description: 'Tens 5 hábitos ativos',
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF64D2FF),
      unlocked: total >= 5,
    ),
    HabitBadge(
      id: 'ten_habits',
      title: 'Obsessivo',
      description: 'Tens 10 hábitos ativos',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFFFFD60A),
      unlocked: total >= 10,
    ),
    HabitBadge(
      id: 'streak_3',
      title: '3 Dias',
      description: 'Primeiro mini-streak!',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF9F0A),
      unlocked: best >= 3,
    ),
    HabitBadge(
      id: 'streak_7',
      title: 'Uma Semana',
      description: '7 dias seguidos num hábito',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFFB300),
      unlocked: best >= 7,
    ),
    HabitBadge(
      id: 'streak_14',
      title: '2 Semanas',
      description: '14 dias sem falhar',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF6B00),
      unlocked: best >= 14,
    ),
    HabitBadge(
      id: 'streak_21',
      title: 'Hábito Formado',
      description: '21 dias — ciência diz que é suficiente',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF30D158),
      unlocked: best >= 21,
    ),
    HabitBadge(
      id: 'streak_30',
      title: 'Um Mês',
      description: '30 dias inteiros sem falhar',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD60A),
      unlocked: best >= 30,
    ),
    HabitBadge(
      id: 'streak_60',
      title: 'Dois Meses',
      description: '60 dias de streak — impressionante',
      icon: Icons.military_tech_rounded,
      color: const Color(0xFF64D2FF),
      unlocked: best >= 60,
    ),
    HabitBadge(
      id: 'streak_100',
      title: 'Centenário',
      description: '100 dias. Lendário.',
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFFF375F),
      unlocked: best >= 100,
    ),
    HabitBadge(
      id: 'streak_365',
      title: 'Um Ano',
      description: '365 dias sem parar. Imparável.',
      icon: Icons.diamond_rounded,
      color: const Color(0xFF5E5CE6),
      unlocked: best >= 365,
    ),
    HabitBadge(
      id: 'perfect_day',
      title: 'Dia Perfeito',
      description: 'Completaste todos os hábitos hoje',
      icon: Icons.done_all_rounded,
      color: const Color(0xFF30D158),
      unlocked: allDone,
    ),
    HabitBadge(
      id: 'half_done',
      title: 'Meio Caminho',
      description: 'Completaste metade dos hábitos hoje',
      icon: Icons.pie_chart_rounded,
      color: const Color(0xFFFF9F0A),
      unlocked: total > 0 && completedCount >= (total / 2).ceil(),
    ),
    HabitBadge(
      id: 'total_streak_50',
      title: 'Força Coletiva',
      description: 'Streak total de todos os hábitos ≥ 50',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFFD60A),
      unlocked: totalStreak >= 50,
    ),
    HabitBadge(
      id: 'total_streak_200',
      title: 'Exército de Hábitos',
      description: 'Streak total ≥ 200',
      icon: Icons.shield_rounded,
      color: const Color(0xFFFF375F),
      unlocked: totalStreak >= 200,
    ),
    HabitBadge(
      id: 'reminder_set',
      title: 'Com Alarme',
      description: 'Configuraste um lembrete',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF64D2FF),
      unlocked: withReminder >= 1,
    ),
    HabitBadge(
      id: 'all_reminders',
      title: 'Tudo Programado',
      description: 'Todos os hábitos têm lembrete',
      icon: Icons.notifications_rounded,
      color: const Color(0xFFBF5AF2),
      unlocked: total > 0 && withReminder == total,
    ),
    HabitBadge(
      id: 'early_bird',
      title: 'Madrugador',
      description: 'Tens um lembrete antes das 7h',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFFD60A),
      unlocked: habits.any(
        (h) => h.reminderEnabled && (h.reminderHour ?? 99) < 7,
      ),
    ),
    HabitBadge(
      id: 'night_owl',
      title: 'Coruja Noturna',
      description: 'Tens um lembrete depois das 22h',
      icon: Icons.bedtime_rounded,
      color: const Color(0xFF5E5CE6),
      unlocked: habits.any(
        (h) => h.reminderEnabled && (h.reminderHour ?? 0) >= 22,
      ),
    ),
    HabitBadge(
      id: 'variety',
      title: 'Polivalente',
      description: 'Tens hábitos de 3 categorias diferentes',
      icon: Icons.category_rounded,
      color: const Color(0xFF30D158),
      unlocked: _hasVariety(habits, 3),
    ),
    HabitBadge(
      id: 'comeback',
      title: 'De Volta',
      description: 'Recomeçaste um hábito após streak 0',
      icon: Icons.refresh_rounded,
      color: const Color(0xFFFF9F0A),
      unlocked: habits.any((h) => h.streak > 0 && !h.completedToday),
    ),
    HabitBadge(
      id: 'consistent',
      title: 'Consistente',
      description: 'Todos os hábitos com streak ≥ 3',
      icon: Icons.trending_up_rounded,
      color: const Color(0xFF64D2FF),
      unlocked: total > 0 && habits.every((h) => h.streak >= 3),
    ),
    HabitBadge(
      id: 'iron_will',
      title: 'Vontade de Ferro',
      description: 'Todos os hábitos com streak ≥ 7',
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFFFF375F),
      unlocked: total > 0 && habits.every((h) => h.streak >= 7),
    ),
    HabitBadge(
      id: 'legend',
      title: 'Lenda',
      description: 'Desbloqueaste 20 ou mais conquistas',
      icon: Icons.stars_rounded,
      color: const Color(0xFFFFD60A),
      unlocked: false,
    ),
  ];
}

bool _hasVariety(List<Habit> habits, int minCategories) =>
    habits.map((h) => h.icon.codePoint).toSet().length >= minCategories;

List<HabitBadge> computeBadgesResolved(List<Habit> habits) {
  final raw = computeBadges(habits);
  final unlockedCount = raw.where((b) => b.unlocked).length;
  return raw.map((b) {
    if (b.id == 'legend') {
      return HabitBadge(
        id: b.id,
        title: b.title,
        description: b.description,
        icon: b.icon,
        color: b.color,
        unlocked: unlockedCount >= 20,
      );
    }
    return b;
  }).toList();
}

class BadgesScreen extends StatelessWidget {
  final List<Habit> habits;
  const BadgesScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProviderScope.of(context);
    final badges = computeBadgesResolved(habits);
    final unlocked = badges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(unlocked, badges.length, theme),
              const SizedBox(height: 24),
              _buildProgressCard(unlocked, badges.length, theme),
              const SizedBox(height: 24),
              Text(
                'CONQUISTAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textHint,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: badges.map((b) => _buildBadgeCard(b, theme)).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total, ThemeProvider theme) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '$unlocked/$total\nconquistas',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -1,
          height: 1.1,
        ),
      ),
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFFFD60A),
          size: 28,
        ),
      ),
    ],
  );

  Widget _buildProgressCard(int unlocked, int total, ThemeProvider theme) {
    final progress = total == 0 ? 0.0 : unlocked / total;
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
              Text(
                'Progresso',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unlocked == total
                ? 'Desbloqueaste todas as conquistas! 🏆'
                : 'Faltam ${total - unlocked} conquistas para completar.',
            style: TextStyle(fontSize: 12, color: theme.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(HabitBadge badge, ThemeProvider theme) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: badge.unlocked ? theme.surface : theme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.unlocked
                ? badge.color.withValues(alpha: 0.3)
                : theme.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badge.unlocked
                    ? badge.color.withValues(alpha: 0.15)
                    : theme.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
                color: badge.unlocked ? badge.color : theme.textHint,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badge.unlocked ? theme.textPrimary : theme.textHint,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 10,
                height: 1.3,
                color: badge.unlocked ? theme.textSecondary : theme.textHint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
