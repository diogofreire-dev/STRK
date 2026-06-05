import 'package:flutter/material.dart';
import 'habit.dart';

class StatsScreen extends StatelessWidget {
  final List<Habit> habits;

  const StatsScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildTodayCard(completed, total, progress),
              const SizedBox(height: 16),
              _buildStatsGrid(bestStreak, avgStreak),
              const SizedBox(height: 24),
              _buildSectionLabel('Hábitos por streak'),
              const SizedBox(height: 12),
              _buildStreakList(),
              const SizedBox(height: 24),
              _buildSectionLabel('Progresso de hoje'),
              const SizedBox(height: 12),
              _buildHabitBars(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOJE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color.fromRGBO(13, 13, 13, 0.5),
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
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromRGBO(13, 13, 13, 0.35),
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
                      color: Color(0xFF0D0D0D),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'concluído',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromRGBO(13, 13, 13, 0.5),
                    ),
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
              backgroundColor: const Color.fromRGBO(13, 13, 13, 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0D0D0D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int bestStreak, double avgStreak) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Melhor streak',
            value: '$bestStreak',
            unit: 'dias',
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF9500),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Média de streak',
            value: avgStreak.toStringAsFixed(1),
            unit: 'dias',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFC8FF00),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Total hábitos',
            value: '${habits.length}',
            unit: 'hábitos',
            icon: Icons.checklist_rounded,
            iconColor: const Color(0xFF64D2FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE8E8E8),
              letterSpacing: -1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: const Color.fromRGBO(255, 255, 255, 0.3),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: const Color.fromRGBO(255, 255, 255, 0.25),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color.fromRGBO(255, 255, 255, 0.3),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildStreakList() {
    if (habits.isEmpty) {
      return _buildEmpty('Ainda não tens hábitos.');
    }

    final sorted = [...habits]..sort((a, b) => b.streak.compareTo(a.streak));
    final maxStreak = sorted.first.streak;

    return Column(
      children: sorted.map((habit) {
        final pct = maxStreak == 0 ? 0.0 : habit.streak / maxStreak;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  habit.icon,
                  size: 16,
                  color: const Color(0xFFC8FF00),
                ),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE8E8E8),
                          ),
                        ),
                        Text(
                          '${habit.streak} dias',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC8FF00),
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
                        backgroundColor: const Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.06,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFC8FF00),
                        ),
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

  Widget _buildHabitBars() {
    if (habits.isEmpty) return _buildEmpty('Ainda não tens hábitos.');

    return Column(
      children: habits.map((habit) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: habit.completedToday
                  ? const Color.fromRGBO(200, 255, 0, 0.25)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                habit.completedToday
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: habit.completedToday
                    ? const Color(0xFFC8FF00)
                    : const Color.fromRGBO(255, 255, 255, 0.15),
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
                        ? const Color(0xFFE8E8E8)
                        : const Color.fromRGBO(255, 255, 255, 0.4),
                  ),
                ),
              ),
              Text(
                habit.completedToday ? 'Feito ✓' : 'Por fazer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: habit.completedToday
                      ? const Color(0xFFC8FF00)
                      : const Color.fromRGBO(255, 255, 255, 0.2),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          fontSize: 14,
        ),
      ),
    );
  }
}
