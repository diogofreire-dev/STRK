import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit.dart';
import 'package:flutter/material.dart';

class Storage {
  static const _key = 'habits';
  static const _dateKey = 'last_open_date';

  static final Map<String, IconData> _iconMap = {
    'water': Icons.water_drop_outlined,
    'fitness': Icons.fitness_center_outlined,
    'book': Icons.menu_book_outlined,
    'meditation': Icons.self_improvement_outlined,
    'sleep': Icons.bedtime_outlined,
    'food': Icons.restaurant_outlined,
    'code': Icons.code_outlined,
    'music': Icons.music_note_outlined,
    'run': Icons.directions_run_outlined,
    'heart': Icons.favorite_outline_rounded,
    'idea': Icons.lightbulb_outline_rounded,
    'star': Icons.star_outline_rounded,
  };

  static String _iconToKey(IconData icon) {
    return _iconMap.entries
        .firstWhere((e) => e.value == icon,
            orElse: () => const MapEntry('star', Icons.star_outline_rounded))
        .key;
  }

  static IconData _keyToIcon(String key) {
    return _iconMap[key] ?? Icons.star_outline_rounded;
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final data = habits.map((h) => {
      'id': h.id,
      'name': h.name,
      'icon': _iconToKey(h.icon),
      'completedToday': h.completedToday,
      'streak': h.streak,
    }).toList();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List<dynamic> data = jsonDecode(raw);
    return data.map((h) => Habit(
      id: h['id'],
      name: h['name'],
      icon: _keyToIcon(h['icon']),
      completedToday: h['completedToday'],
      streak: h['streak'],
    )).toList();
  }

  static Future<bool> shouldResetToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_dateKey);
    final today = _todayString();
    return lastDate != today;
  }

  static Future<void> saveOpenDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _todayString());
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}