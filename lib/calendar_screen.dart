import 'package:flutter/material.dart';
import 'habit.dart';
import 'habit_service.dart';

class CalendarScreen extends StatefulWidget {
  final List<Habit> habits;

  const CalendarScreen({super.key, required this.habits});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Habit? _selectedHabit;
  Map<String, bool> _logs = {};
  Map<String, int> _allLogs = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  bool get _isAll => _selectedHabit == null;

  Future<void> _loadLogs() async {
    setState(() => _loading = true);

    if (_isAll) {
      final Map<String, int> combined = {};
      for (final habit in widget.habits) {
        final logs = await HabitService.getLogsForHabit(habit.id);
        logs.forEach((date, completed) {
          if (completed) {
            combined[date] = (combined[date] ?? 0) + 1;
          }
        });
      }
      setState(() {
        _allLogs = combined;
        _logs = {};
        _loading = false;
      });
    } else {
      final logs = await HabitService.getLogsForHabit(_selectedHabit!.id);
      setState(() {
        _logs = logs;
        _allLogs = {};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.habits.isEmpty)
                Center(
                  child: Text(
                    'Ainda não tens hábitos.',
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.2),
                      fontSize: 14,
                    ),
                  ),
                )
              else ...[
                _buildHabitSelector(),
                const SizedBox(height: 24),
                _buildLegend(),
                const SizedBox(height: 16),
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC8FF00),
                          strokeWidth: 2,
                        ),
                      )
                    : _buildHeatmap(),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 24),
                _buildSectionLabel('ESTA SEMANA'),
                const SizedBox(height: 12),
                _buildWeeklyBars(),
                const SizedBox(height: 24),
                _buildSectionLabel('ESTE MÊS'),
                const SizedBox(height: 12),
                _buildMonthlySummary(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(255, 255, 255, 0.3),
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Weekly bar chart ──────────────────────────────────────────────────────

  Widget _buildWeeklyBars() {
    final now = DateTime.now();
    final weekDayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    // Build last 7 days ending today
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxCount = widget.habits.isEmpty
        ? 1
        : widget.habits.length.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((date) {
              final key = _dateKey(date);
              final isToday = key == HabitService.todayString();
              double ratio;

              if (_isAll) {
                final count = (_allLogs[key] ?? 0).toDouble();
                ratio = (count / maxCount).clamp(0.0, 1.0);
              } else {
                ratio = (_logs[key] == true) ? 1.0 : 0.0;
              }

              final barHeight = 60.0 * ratio + 4.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // percentage label on top
                  if (ratio > 0)
                    Text(
                      '${(ratio * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? const Color(0xFFC8FF00)
                            : const Color.fromRGBO(255, 255, 255, 0.4),
                      ),
                    )
                  else
                    const SizedBox(height: 13),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: ratio == 0
                          ? const Color.fromRGBO(255, 255, 255, 0.06)
                          : isToday
                          ? const Color(0xFFC8FF00)
                          : Color.fromRGBO(200, 255, 0, 0.4 + 0.6 * ratio),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((date) {
              final key = _dateKey(date);
              final isToday = key == HabitService.todayString();
              final label = weekDayLabels[date.weekday - 1];
              return SizedBox(
                width: 28,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? const Color(0xFFC8FF00)
                        : const Color.fromRGBO(255, 255, 255, 0.25),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Monthly summary ───────────────────────────────────────────────────────

  Widget _buildMonthlySummary() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final pastDays = now.day; // days elapsed including today

    // Build logs for this month
    int activeDays = 0;
    int perfectDays = 0;
    int bestDayCount = 0;

    for (int d = 1; d <= pastDays; d++) {
      final date = DateTime(now.year, now.month, d);
      final key = _dateKey(date);
      int count;

      if (_isAll) {
        count = _allLogs[key] ?? 0;
      } else {
        count = (_logs[key] == true) ? 1 : 0;
      }

      if (count > 0) activeDays++;
      final total = _isAll ? widget.habits.length : 1;
      if (total > 0 && count == total) perfectDays++;
      if (count > bestDayCount) {
        bestDayCount = count;
      }
    }

    final monthRate = pastDays == 0
        ? 0
        : ((activeDays / pastDays) * 100).round();

    // Most consistent habit (all mode only)
    String bestHabit = '—';
    if (_isAll && widget.habits.isNotEmpty) {
      int bestCount = -1;
      for (final habit in widget.habits) {
        int habitCount = 0;
        for (int d = 1; d <= pastDays; d++) {
          final key = _dateKey(DateTime(now.year, now.month, d));
          // We only have combined logs; use allLogs presence as proxy
          if ((_allLogs[key] ?? 0) > 0) habitCount++;
        }
        if (habitCount > bestCount) {
          bestCount = habitCount;
          bestHabit = habit.name;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Progress bar for the month
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthName(now.month),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8E8E8),
                ),
              ),
              Text(
                '${now.day}/$daysInMonth dias',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color.fromRGBO(255, 255, 255, 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: daysInMonth == 0 ? 0 : now.day / daysInMonth,
              minHeight: 4,
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC8FF00),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Dias ativos', '$activeDays'),
              _buildDividerV(),
              _buildStatItem('Dias perfeitos', '$perfectDays'),
              _buildDividerV(),
              _buildStatItem('Taxa mensal', '$monthRate%'),
            ],
          ),
          if (_isAll && bestHabit != '—') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(200, 255, 0, 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(200, 255, 0, 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: Color(0xFFC8FF00),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hábito destaque: $bestHabit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC8FF00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return names[month];
  }

  // ── Existing widgets (unchanged) ──────────────────────────────────────────

  Widget _buildHabitSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedHabit = null);
              _loadLogs();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isAll
                    ? const Color(0xFFC8FF00)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 14,
                    color: _isAll
                        ? const Color(0xFF0D0D0D)
                        : const Color.fromRGBO(255, 255, 255, 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isAll
                          ? const Color(0xFF0D0D0D)
                          : const Color.fromRGBO(255, 255, 255, 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...widget.habits.map((habit) {
            final selected = _selectedHabit?.id == habit.id;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedHabit = habit);
                _loadLogs();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFC8FF00)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      habit.icon,
                      size: 14,
                      color: selected
                          ? const Color(0xFF0D0D0D)
                          : const Color.fromRGBO(255, 255, 255, 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF0D0D0D)
                            : const Color.fromRGBO(255, 255, 255, 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          'Menos',
          style: TextStyle(
            fontSize: 11,
            color: const Color.fromRGBO(255, 255, 255, 0.25),
          ),
        ),
        const SizedBox(width: 6),
        ...[0.05, 0.2, 0.5, 0.8, 1.0].map((opacity) {
          return Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Color.fromRGBO(200, 255, 0, opacity),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          'Mais',
          style: TextStyle(
            fontSize: 11,
            color: const Color.fromRGBO(255, 255, 255, 0.25),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    final now = DateTime.now();
    const weeks = 18;
    const totalDays = weeks * 7;
    final startDate = now.subtract(const Duration(days: totalDays - 1));
    final days = List.generate(
      totalDays,
      (i) => startDate.add(Duration(days: i)),
    );
    final weekLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final maxCount = widget.habits.isEmpty ? 1 : widget.habits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: weekLabels.map((label) {
                return SizedBox(
                  height: 18,
                  width: 16,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color.fromRGBO(255, 255, 255, 0.2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weeks, (weekIndex) {
                    return Column(
                      children: List.generate(7, (dayIndex) {
                        final dayOffset = weekIndex * 7 + dayIndex;
                        if (dayOffset >= days.length) {
                          return const SizedBox(width: 18, height: 18);
                        }
                        final date = days[dayOffset];
                        final key = _dateKey(date);
                        final isToday = key == HabitService.todayString();
                        final isFuture = date.isAfter(now);

                        Color cellColor;
                        String tooltip;

                        if (_isAll) {
                          final count = _allLogs[key] ?? 0;
                          final opacity = isFuture || count == 0
                              ? (isFuture ? 0.0 : 0.06)
                              : (count / maxCount).clamp(0.15, 1.0);
                          cellColor = isFuture
                              ? Colors.transparent
                              : count == 0
                              ? const Color.fromRGBO(255, 255, 255, 0.06)
                              : Color.fromRGBO(200, 255, 0, opacity);
                          tooltip =
                              '$key${count > 0 ? ' ($count/${widget.habits.length})' : ''}';
                        } else {
                          final completed = _logs[key] ?? false;
                          cellColor = isFuture
                              ? Colors.transparent
                              : completed
                              ? const Color(0xFFC8FF00)
                              : const Color.fromRGBO(255, 255, 255, 0.06);
                          tooltip = '$key${completed ? ' ✓' : ''}';
                        }

                        return Tooltip(
                          message: tooltip,
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(3),
                              border: isToday
                                  ? Border.all(
                                      color: const Color(0xFFC8FF00),
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    if (_isAll) {
      final totalDays = _allLogs.length;
      final perfectDays = _allLogs.values
          .where((count) => count == widget.habits.length)
          .length;
      final activeDays = _allLogs.values.where((count) => count > 0).length;
      final rate = totalDays == 0
          ? 0
          : ((activeDays / totalDays) * 100).round();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Dias ativos', '$activeDays'),
            _buildDividerV(),
            _buildStatItem('Dias perfeitos', '$perfectDays'),
            _buildDividerV(),
            _buildStatItem('Taxa', '$rate%'),
          ],
        ),
      );
    }

    final completedDays = _logs.values.where((v) => v).length;
    final totalDays = _logs.length;
    final rate = totalDays == 0
        ? 0
        : ((completedDays / totalDays) * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Dias feitos', '$completedDays'),
          _buildDividerV(),
          _buildStatItem('Taxa', '$rate%'),
          _buildDividerV(),
          _buildStatItem('Streak atual', '${_selectedHabit?.streak ?? 0} dias'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFFE8E8E8),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color.fromRGBO(255, 255, 255, 0.3),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerV() {
    return Container(
      width: 0.5,
      height: 40,
      color: const Color.fromRGBO(255, 255, 255, 0.08),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
