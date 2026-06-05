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
}
