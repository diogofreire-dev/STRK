import 'package:flutter/material.dart';
import 'habit.dart';
import 'habit_service.dart';

const _kOrange = Color(0xFFFF6B00);
const _kAmber = Color(0xFFFFB300);
const _kBg = Color(0xFF0D0D0D);
const _kSurf = Color(0xFF1A1A1A);
const _kText = Color(0xFFE8E8E8);

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
          if (completed) combined[date] = (combined[date] ?? 0) + 1;
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
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.habits.isEmpty)
                const Center(
                  child: Text(
                    'Ainda não tens hábitos.',
                    style: TextStyle(color: Color(0x33FFFFFF), fontSize: 14),
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
                          color: _kOrange,
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
        color: Color(0x4DFFFFFF),
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Weekly bars ───────────────────────────────────────────────────────────

  Widget _buildWeeklyBars() {
    final now = DateTime.now();
    final weekDayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxCount = widget.habits.isEmpty
        ? 1
        : widget.habits.length.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurf,
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
                ratio = ((_allLogs[key] ?? 0).toDouble() / maxCount).clamp(
                  0.0,
                  1.0,
                );
              } else {
                ratio = (_logs[key] == true) ? 1.0 : 0.0;
              }
              final barH = 60.0 * ratio + 4.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (ratio > 0)
                    Text(
                      '${(ratio * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isToday ? _kOrange : Colors.white24,
                      ),
                    )
                  else
                    const SizedBox(height: 13),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barH,
                    decoration: BoxDecoration(
                      color: ratio == 0
                          ? Colors.white10
                          : isToday
                          ? _kOrange
                          : Color.lerp(
                              const Color(0x66FF6B00),
                              _kAmber,
                              ratio,
                            )!,
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
              return SizedBox(
                width: 28,
                child: Text(
                  weekDayLabels[date.weekday - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? _kOrange : Colors.white24,
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
    final pastDays = now.day;

    int activeDays = 0, perfectDays = 0, bestDayCount = 0;
    for (int d = 1; d <= pastDays; d++) {
      final key = _dateKey(DateTime(now.year, now.month, d));
      final count = _isAll
          ? (_allLogs[key] ?? 0)
          : ((_logs[key] == true) ? 1 : 0);
      if (count > 0) activeDays++;
      final total = _isAll ? widget.habits.length : 1;
      if (total > 0 && count == total) perfectDays++;
      if (count > bestDayCount) bestDayCount = count;
    }
    final monthRate = pastDays == 0
        ? 0
        : ((activeDays / pastDays) * 100).round();

    String bestHabit = '—';
    if (_isAll && widget.habits.isNotEmpty) {
      int bestCount = -1;
      for (final habit in widget.habits) {
        int hc = 0;
        for (int d = 1; d <= pastDays; d++) {
          if ((_allLogs[_dateKey(DateTime(now.year, now.month, d))] ?? 0) > 0)
            hc++;
        }
        if (hc > bestCount) {
          bestCount = hc;
          bestHabit = habit.name;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurf,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthName(now.month),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              Text(
                '${now.day}/$daysInMonth dias',
                style: const TextStyle(fontSize: 11, color: Color(0x4DFFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: daysInMonth == 0 ? 0 : now.day / daysInMonth,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_kOrange),
            ),
          ),
          const SizedBox(height: 20),
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
                color: _kOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: _kOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hábito destaque: $bestHabit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kOrange,
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

  String _monthName(int m) {
    const n = [
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
    return n[m];
  }

  // ── Habit selector ────────────────────────────────────────────────────────

  Widget _buildHabitSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(null, Icons.grid_view_rounded, 'Todos'),
          ...widget.habits.map((h) => _chip(h, h.icon, h.name)),
        ],
      ),
    );
  }

  Widget _chip(Habit? habit, IconData icon, String label) {
    final selected = habit == null ? _isAll : _selectedHabit?.id == habit.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHabit = habit);
        _loadLogs();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kOrange : _kSurf,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      children: [
        const Text(
          'Menos',
          style: TextStyle(fontSize: 11, color: Color(0x40FFFFFF)),
        ),
        const SizedBox(width: 6),
        ...[0.08, 0.25, 0.5, 0.75, 1.0].map(
          (o) => Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Color.lerp(const Color(0x14FF6B00), _kAmber, o),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Mais',
          style: TextStyle(fontSize: 11, color: Color(0x40FFFFFF)),
        ),
      ],
    );
  }

  // ── Heatmap ───────────────────────────────────────────────────────────────

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
              children: weekLabels
                  .map(
                    (l) => SizedBox(
                      height: 18,
                      width: 16,
                      child: Text(
                        l,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0x33FFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    weeks,
                    (wi) => Column(
                      children: List.generate(7, (di) {
                        final idx = wi * 7 + di;
                        if (idx >= days.length)
                          return const SizedBox(width: 18, height: 18);
                        final date = days[idx];
                        final key = _dateKey(date);
                        final isToday = key == HabitService.todayString();
                        final isFuture = date.isAfter(now);

                        Color cellColor;
                        if (_isAll) {
                          final count = _allLogs[key] ?? 0;
                          if (isFuture || count == 0) {
                            cellColor = isFuture
                                ? Colors.transparent
                                : Colors.white10;
                          } else {
                            final t = (count / maxCount).clamp(0.15, 1.0);
                            cellColor = Color.lerp(
                              const Color(0x40FF6B00),
                              _kAmber,
                              t,
                            )!;
                          }
                        } else {
                          final done = _logs[key] ?? false;
                          cellColor = isFuture
                              ? Colors.transparent
                              : done
                              ? _kOrange
                              : Colors.white10;
                        }

                        return Tooltip(
                          message: key,
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(3),
                              border: isToday
                                  ? Border.all(color: _kOrange, width: 1.5)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    if (_isAll) {
      final activeDays = _allLogs.values.where((c) => c > 0).length;
      final perfectDays = _allLogs.values
          .where((c) => c == widget.habits.length)
          .length;
      final total = _allLogs.length;
      final rate = total == 0 ? 0 : ((activeDays / total) * 100).round();
      return _statsCard([
        _buildStatItem('Dias ativos', '$activeDays'),
        _buildDividerV(),
        _buildStatItem('Dias perfeitos', '$perfectDays'),
        _buildDividerV(),
        _buildStatItem('Taxa', '$rate%'),
      ]);
    }
    final done = _logs.values.where((v) => v).length;
    final total = _logs.length;
    final rate = total == 0 ? 0 : ((done / total) * 100).round();
    return _statsCard([
      _buildStatItem('Dias feitos', '$done'),
      _buildDividerV(),
      _buildStatItem('Taxa', '$rate%'),
      _buildDividerV(),
      _buildStatItem('Streak atual', '${_selectedHabit?.streak ?? 0} dias'),
    ]);
  }

  Widget _statsCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kSurf,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    ),
  );

  Widget _buildStatItem(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _kText,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0x4DFFFFFF),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _buildDividerV() =>
      Container(width: 0.5, height: 40, color: Colors.white12);

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
