import 'package:flutter/material.dart';

/// Data no formato `YYYY-MM-DD` (hora local), usada como chave de dia nos
/// logs e no [Habit.lastCompletedDate].
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Dia anterior a [d]. Usa o construtor em vez de `subtract(Duration(days: 1))`
/// para não falhar nos dias de mudança de hora (23h ou 25h).
DateTime previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

/// "1 dia" / "5 dias".
String dias(int n) => n == 1 ? '1 dia' : '$n dias';

class Habit {
  final String id;
  String name;
  IconData icon;
  bool completedToday;
  int streak;

  /// Último dia (ver [dateKey]) em que o hábito foi concluído. É a partir
  /// daqui que se sabe se o streak continua vivo ou se foi quebrado.
  String? lastCompletedDate;
  bool reminderEnabled;
  int? reminderHour;
  int? reminderMinute;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.completedToday = false,
    this.streak = 0,
    this.lastCompletedDate,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  /// Alterna a conclusão de hoje e ajusta o streak em conformidade:
  /// marcar como feito soma 1, desmarcar subtrai 1. Ao desmarcar, se ainda
  /// sobrar streak é porque a sequência terminava ontem.
  void toggleCompletion({DateTime? now}) {
    final today = now ?? DateTime.now();
    completedToday = !completedToday;
    if (completedToday) {
      streak++;
      lastCompletedDate = dateKey(today);
    } else {
      if (streak > 0) streak--;
      lastCompletedDate = streak > 0 ? dateKey(previousDay(today)) : null;
    }
  }

  /// Põe o hábito em dia com a data atual: só conta como feito hoje se a
  /// última conclusão foi hoje, e o streak quebra se falhou pelo menos um
  /// dia inteiro (a última conclusão não é nem hoje nem ontem).
  void refreshForDay(DateTime now) {
    final today = dateKey(now);
    final yesterday = dateKey(previousDay(now));
    completedToday = lastCompletedDate == today;
    if (lastCompletedDate != today && lastCompletedDate != yesterday) {
      streak = 0;
    }
  }
}
