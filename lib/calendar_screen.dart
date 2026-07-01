import 'package:flutter/material.dart';
import 'habit.dart';
import 'habit_service.dart';
import 'theme_provider.dart';

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
    final theme = ThemeProviderScope.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
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
                    style: TextStyle(color: theme.textHint, fontSize: 14),
                  ),
                )
              else ...[
                _buildHabitSelector(theme),
                const SizedBox(height: 24),
                _buildLegend(theme),
                const SizedBox(height: 16),
                _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.accent,
                          strokeWidth: 2,
                        ),
                      )
                    : _buildHeatmap(theme),
                const SizedBox(height: 24),
                _buildStats(theme),
                const SizedBox(height: 24),
                _sectionLabel('ESTA SEMANA', theme),
                const SizedBox(height: 12),
                _buildWeeklyBars(theme),
                const SizedBox(height: 24),
                _sectionLabel('ESTE MÊS', theme),
                const SizedBox(height: 12),
                _buildMonthlySummary(theme),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ThemeProvider theme) => Text(
    label,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: theme.textHint,
      letterSpacing: 0.8,
    ),
  );

  Widget _buildHabitSelector(ThemeProvider theme) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _chip(null, Icons.grid_view_rounded, 'Todos', theme),
        ...widget.habits.map((h) => _chip(h, h.icon, h.name, theme)),
      ],
    ),
  );

  Widget _chip(Habit? habit, IconData icon, String label, ThemeProvider theme) {
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
          color: selected ? theme.accent : theme.surface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : theme.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeProvider theme) => Row(
    children: [
      Text('Menos', style: TextStyle(fontSize: 11, color: theme.textHint)),
      const SizedBox(width: 6),
      ...[0.08, 0.25, 0.5, 0.75, 1.0].map(
        (o) => Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.accent.withValues(alpha: 0.15),
              theme.accent,
              o,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('Mais', style: TextStyle(fontSize: 11, color: theme.textHint)),
    ],
  );

  Widget _buildHeatmap(ThemeProvider theme) {
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
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textHint,
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
                        if (idx >= days.length) {
                          return const SizedBox(width: 18, height: 18);
                        }
                        final date = days[idx];
                        final key = _dateKey(date);
                        final isToday = key == HabitService.todayString();
                        final isFuture = date.isAfter(now);
                        Color cellColor;
                        if (_isAll) {
                          final count = _allLogs[key] ?? 0;
                          cellColor = isFuture
                              ? Colors.transparent
                              : count == 0
                              ? theme.surfaceAlt
                              : Color.lerp(
                                  theme.accent.withValues(alpha: 0.3),
                                  theme.accent,
                                  (count / maxCount).clamp(0.15, 1.0),
                                )!;
                        } else {
                          final done = _logs[key] ?? false;
                          cellColor = isFuture
                              ? Colors.transparent
                              : done
                              ? theme.accent
                              : theme.surfaceAlt;
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
                                  ? Border.all(color: theme.accent, width: 1.5)
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

  Widget _buildWeeklyBars(ThemeProvider theme) {
    final now = DateTime.now();
    final weekDayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxCount = widget.habits.isEmpty
        ? 1
        : widget.habits.length.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
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
              final ratio = _isAll
                  ? ((_allLogs[key] ?? 0).toDouble() / maxCount).clamp(0.0, 1.0)
                  : (_logs[key] == true)
                  ? 1.0
                  : 0.0;
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
                        color: isToday ? theme.accent : theme.textHint,
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
                          ? theme.surfaceAlt
                          : isToday
                          ? theme.accent
                          : Color.lerp(
                              theme.accent.withValues(alpha: 0.4),
                              theme.accent,
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
                    color: isToday ? theme.accent : theme.textHint,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(ThemeProvider theme) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final pastDays = now.day;
    int activeDays = 0, perfectDays = 0;
    for (int d = 1; d <= pastDays; d++) {
      final key = _dateKey(DateTime(now.year, now.month, d));
      final count = _isAll
          ? (_allLogs[key] ?? 0)
          : ((_logs[key] == true) ? 1 : 0);
      if (count > 0) activeDays++;
      final total = _isAll ? widget.habits.length : 1;
      if (total > 0 && count == total) perfectDays++;
    }
    final monthRate = pastDays == 0
        ? 0
        : ((activeDays / pastDays) * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthName(now.month),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                '${now.day}/$daysInMonth dias',
                style: TextStyle(fontSize: 11, color: theme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: daysInMonth == 0 ? 0 : now.day / daysInMonth,
              minHeight: 4,
              backgroundColor: theme.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Dias ativos', '$activeDays', theme),
              _dividerV(theme),
              _statItem('Dias perfeitos', '$perfectDays', theme),
              _dividerV(theme),
              _statItem('Taxa mensal', '$monthRate%', theme),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
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
  ][m];

  Widget _buildStats(ThemeProvider theme) {
    if (_isAll) {
      final activeDays = _allLogs.values.where((c) => c > 0).length;
      final perfectDays = _allLogs.values
          .where((c) => c == widget.habits.length)
          .length;
      final total = _allLogs.length;
      final rate = total == 0 ? 0 : ((activeDays / total) * 100).round();
      return _statsCard([
        _statItem('Dias ativos', '$activeDays', theme),
        _dividerV(theme),
        _statItem('Dias perfeitos', '$perfectDays', theme),
        _dividerV(theme),
        _statItem('Taxa', '$rate%', theme),
      ], theme);
    }
    final done = _logs.values.where((v) => v).length;
    final total = _logs.length;
    final rate = total == 0 ? 0 : ((done / total) * 100).round();
    return _statsCard([
      _statItem('Dias feitos', '$done', theme),
      _dividerV(theme),
      _statItem('Taxa', '$rate%', theme),
      _dividerV(theme),
      _statItem('Streak atual', '${_selectedHabit?.streak ?? 0} dias', theme),
    ], theme);
  }

  Widget _statsCard(List<Widget> children, ThemeProvider theme) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    ),
  );

  Widget _statItem(String label, String value, ThemeProvider theme) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: theme.textHint,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _dividerV(ThemeProvider theme) =>
      Container(width: 0.5, height: 40, color: theme.divider);

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
