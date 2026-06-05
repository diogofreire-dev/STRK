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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.habits.isNotEmpty) {
      _selectedHabit = widget.habits.first;
      _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    if (_selectedHabit == null) return;
    setState(() => _loading = true);
    final logs = await HabitService.getLogsForHabit(_selectedHabit!.id);
    setState(() {
      _logs = logs;
      _loading = false;
    });
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.habits.map((habit) {
          final selected = _selectedHabit?.id == habit.id;
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
        }).toList(),
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
    final weeks = 18;
    final totalDays = weeks * 7;
    final startDate = now.subtract(Duration(days: totalDays - 1));

    final days = List.generate(totalDays, (i) {
      return startDate.add(Duration(days: i));
    });

    final weekLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

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
                    style: TextStyle(
                      fontSize: 9,
                      color: const Color.fromRGBO(255, 255, 255, 0.2),
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
                        final completed = _logs[key] ?? false;
                        final isToday =
                            _dateKey(date) == HabitService.todayString();
                        final isFuture = date.isAfter(now);

                        return Tooltip(
                          message: '$key${completed ? ' ✓' : ''}',
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? Colors.transparent
                                  : completed
                                  ? const Color(0xFFC8FF00)
                                  : const Color.fromRGBO(255, 255, 255, 0.06),
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
          style: TextStyle(
            fontSize: 11,
            color: const Color.fromRGBO(255, 255, 255, 0.3),
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
