import 'package:flutter/material.dart';
import 'habit.dart';

const _kOrange = Color(0xFFFF6B00);
const _kAmber = Color(0xFFFFB300);
const _kBg = Color(0xFF0D0D0D);
const _kSurf = Color(0xFF1A1A1A);
const _kText = Color(0xFFE8E8E8);

class Badge {
  final String id, title, description;
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
    final best = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final total = habits.length;
    final allDone =
        total > 0 && habits.where((h) => h.completedToday).length == total;

    return [
      Badge(
        id: 'first_habit',
        title: 'Primeiro Passo',
        description: 'Criaste o teu primeiro hábito',
        icon: Icons.flag_rounded,
        color: _kOrange,
        unlocked: total >= 1,
      ),
      Badge(
        id: 'five_habits',
        title: 'Colecionador',
        description: 'Tens 5 hábitos ativos',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFF64D2FF),
        unlocked: total >= 5,
      ),
      Badge(
        id: 'streak_7',
        title: '7 Dias',
        description: 'Mantiveste um hábito 7 dias seguidos',
        icon: Icons.local_fire_department_rounded,
        color: _kAmber,
        unlocked: best >= 7,
      ),
      Badge(
        id: 'streak_14',
        title: '2 Semanas',
        description: 'Mantiveste um hábito 14 dias seguidos',
        icon: Icons.local_fire_department_rounded,
        color: _kOrange,
        unlocked: best >= 14,
      ),
      Badge(
        id: 'streak_30',
        title: '30 Dias',
        description: 'Um mês inteiro sem falhar!',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFD60A),
        unlocked: best >= 30,
      ),
      Badge(
        id: 'streak_100',
        title: '100 Dias',
        description: 'Lendário. 100 dias de streak.',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFFF375F),
        unlocked: best >= 100,
      ),
      Badge(
        id: 'perfect_day',
        title: 'Dia Perfeito',
        description: 'Completaste todos os hábitos hoje',
        icon: Icons.done_all_rounded,
        color: const Color(0xFF30D158),
        unlocked: allDone,
      ),
      Badge(
        id: 'dedicated',
        title: 'Dedicado',
        description: 'Tens 3 ou mais hábitos ativos',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFBF5AF2),
        unlocked: total >= 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final badges = _computeBadges();
    final unlocked = badges.where((b) => b.unlocked).length;

    return Scaffold(
      backgroundColor: _kBg,
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
              const Text(
                'CONQUISTAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0x4DFFFFFF),
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
                children: badges.map(_buildBadgeCard).toList(),
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
            color: _kText,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _kSurf,
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
        color: _kSurf,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0x66FFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: _kOrange,
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
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_kOrange),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unlocked == total
                ? 'Desbloqueaste todas as conquistas! 🏆'
                : 'Faltam ${total - unlocked} conquistas para completar.',
            style: const TextStyle(fontSize: 12, color: Color(0x4DFFFFFF)),
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
        color: badge.unlocked ? _kSurf : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.color.withValues(alpha: 0.3)
              : Colors.white12,
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
                  : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock_outline_rounded,
              color: badge.unlocked ? badge.color : Colors.white24,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: badge.unlocked ? _kText : Colors.white24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              height: 1.3,
              color: badge.unlocked ? Colors.white38 : Colors.white12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
