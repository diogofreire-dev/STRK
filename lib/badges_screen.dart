import 'package:flutter/material.dart';
import 'habit.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
  });
}

class BadgesScreen extends StatelessWidget {
  final List<Habit> habits;

  const BadgesScreen({super.key, required this.habits});

  List<Badge> _computeBadges() {
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final totalHabits = habits.length;
    final completedToday = habits.where((h) => h.completedToday).length;
    final allDoneToday = totalHabits > 0 && completedToday == totalHabits;

    return [
      Badge(
        id: 'first_habit',
        title: 'Primeiro Passo',
        description: 'Criaste o teu primeiro hábito',
        icon: Icons.flag_rounded,
        color: const Color(0xFFC8FF00),
        unlocked: totalHabits >= 1,
      ),
      Badge(
        id: 'five_habits',
        title: 'Colecionador',
        description: 'Tens 5 hábitos ativos',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF64D2FF),
        unlocked: totalHabits >= 5,
      ),
      Badge(
        id: 'streak_7',
        title: '7 Dias',
        description: 'Mantiveste um hábito 7 dias seguidos',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF9500),
        unlocked: bestStreak >= 7,
      ),
      Badge(
        id: 'streak_14',
        title: '2 Semanas',
        description: 'Mantiveste um hábito 14 dias seguidos',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B00),
        unlocked: bestStreak >= 14,
      ),
      Badge(
        id: 'streak_30',
        title: '30 Dias',
        description: 'Um mês inteiro sem falhar!',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFD60A),
        unlocked: bestStreak >= 30,
      ),
      Badge(
        id: 'streak_100',
        title: '100 Dias',
        description: 'Lendário. 100 dias de streak.',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFFF375F),
        unlocked: bestStreak >= 100,
      ),
      Badge(
        id: 'perfect_day',
        title: 'Dia Perfeito',
        description: 'Completaste todos os hábitos hoje',
        icon: Icons.done_all_rounded,
        color: const Color(0xFF30D158),
        unlocked: allDoneToday,
      ),
      Badge(
        id: 'dedicated',
        title: 'Dedicado',
        description: 'Tens 3 ou mais hábitos ativos',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFBF5AF2),
        unlocked: totalHabits >= 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final badges = _computeBadges();
    final unlocked = badges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(unlocked, badges.length),
              const SizedBox(height: 24),
              _buildProgressCard(unlocked, badges.length),
              const SizedBox(height: 24),
              Text(
                'CONQUISTAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromRGBO(255, 255, 255, 0.3),
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
                children: badges
                    .map((badge) => _buildBadgeCard(badge))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$unlocked/$total\nconquistas',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE8E8E8),
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
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
  }

  Widget _buildProgressCard(int unlocked, int total) {
    final progress = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
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
                  color: const Color.fromRGBO(255, 255, 255, 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC8FF00),
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
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8FF00),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unlocked == total
                ? 'Desbloqueaste todas as conquistas! 🏆'
                : 'Faltam ${total - unlocked} conquistas para completar.',
            style: TextStyle(
              fontSize: 12,
              color: const Color.fromRGBO(255, 255, 255, 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Badge badge) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.3)
              : const Color.fromRGBO(255, 255, 255, 0.05),
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
                  : const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
              color: badge.unlocked
                  ? badge.color
                  : const Color.fromRGBO(255, 255, 255, 0.2),
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: badge.unlocked
                  ? const Color(0xFFE8E8E8)
                  : const Color.fromRGBO(255, 255, 255, 0.25),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color: badge.unlocked
                  ? const Color.fromRGBO(255, 255, 255, 0.35)
                  : const Color.fromRGBO(255, 255, 255, 0.15),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
