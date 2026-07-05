import 'package:flutter/material.dart';

class Habit {
  final String id;
  String name;
  IconData icon;
  bool completedToday;
  int streak;
  bool reminderEnabled;
  int? reminderHour;
  int? reminderMinute;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.completedToday = false,
    this.streak = 0,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
  });

  /// Alterna a conclusão de hoje e ajusta o streak em conformidade:
  /// marcar como feito soma 1, desmarcar subtrai 1.
  void toggleCompletion() {
    completedToday = !completedToday;
    completedToday ? streak++ : streak--;
  }
}
