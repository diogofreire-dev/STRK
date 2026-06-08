import 'package:flutter/material.dart';
import 'habit.dart';

const _kOrange = Color(0xFFFF6B00);
const _kAmber = Color(0xFFFFB300);
const _kEmber = Color(0xFFFF3B00);
const _kBg = Color(0xFF0D0D0D);
const _kSurf = Color(0xFF1A1A1A);
const _kText = Color(0xFFE8E8E8);

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
      backgroundColor: _kBg,
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
        gradient: const LinearGradient(colors: [_kEmber, _kOrange, _kAmber]),
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

  Widget _buildStatsGrid(int bestStreak, double avgStreak) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Melhor streak',
            '$bestStreak',
            'dias',
            Icons.local_fire_department_rounded,
            _kOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Média de streak',
            avgStreak.toStringAsFixed(1),
            'dias',
            Icons.trending_up_rounded,
            _kAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total hábitos',
            '${habits.length}',
            'hábitos',
            Icons.checklist_rounded,
            const Color(0xFF64D2FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurf,
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
              color: _kText,
              letterSpacing: -1,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0x4DFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0x40FFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0x4DFFFFFF),
      letterSpacing: 0.8,
    ),
  );

  Widget _buildStreakList() {
    if (habits.isEmpty) return _buildEmpty('Ainda não tens hábitos.');
    final sorted = [...habits]..sort((a, b) => b.streak.compareTo(a.streak));
    final maxStreak = sorted.first.streak;

    return Column(
      children: sorted.map((habit) {
        final pct = maxStreak == 0 ? 0.0 : habit.streak / maxStreak;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurf,
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
                child: Icon(habit.icon, size: 16, color: _kOrange),
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
                            color: _kText,
                          ),
                        ),
                        Text(
                          '${habit.streak} dias',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kOrange,
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
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _kOrange,
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
      children: habits
          .map(
            (habit) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _kSurf,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: habit.completedToday
                      ? _kOrange.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    habit.completedToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: habit.completedToday ? _kOrange : Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: habit.completedToday ? _kText : Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    habit.completedToday ? 'Feito ✓' : 'Por fazer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: habit.completedToday ? _kOrange : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmpty(String msg) => Center(
    child: Text(
      msg,
      style: const TextStyle(color: Color(0x33FFFFFF), fontSize: 14),
    ),
  );
}
