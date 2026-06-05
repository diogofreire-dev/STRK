import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'habit.dart';

class HabitService {
  static final _db = FirebaseFirestore.instance;

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
        .firstWhere(
          (e) => e.value == icon,
          orElse: () => const MapEntry('star', Icons.star_outline_rounded),
        )
        .key;
  }

  static IconData _keyToIcon(String key) {
    return _iconMap[key] ?? Icons.star_outline_rounded;
  }

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference get _habitsRef =>
      _db.collection('users').doc(_uid).collection('habits');

  static Future<void> saveHabit(Habit habit) async {
    await _habitsRef.doc(habit.id).set({
      'id': habit.id,
      'name': habit.name,
      'icon': _iconToKey(habit.icon),
      'completedToday': habit.completedToday,
      'streak': habit.streak,
      'reminderEnabled': habit.reminderEnabled,
      'reminderHour': habit.reminderHour,
      'reminderMinute': habit.reminderMinute,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteHabit(String id) async {
    await _habitsRef.doc(id).delete();
  }

  static Future<List<Habit>> loadHabits() async {
    final snapshot = await _habitsRef.orderBy('lastUpdated').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Habit(
        id: data['id'],
        name: data['name'],
        icon: _keyToIcon(data['icon']),
        completedToday: data['completedToday'] ?? false,
        streak: data['streak'] ?? 0,
        reminderEnabled: data['reminderEnabled'] ?? false,
        reminderHour: data['reminderHour'] as int?,
        reminderMinute: data['reminderMinute'] as int?,
      );
    }).toList();
  }

  static Future<void> saveAllHabits(List<Habit> habits) async {
    final batch = _db.batch();
    for (final habit in habits) {
      batch.set(_habitsRef.doc(habit.id), {
        'id': habit.id,
        'name': habit.name,
        'icon': _iconToKey(habit.icon),
        'completedToday': habit.completedToday,
        'streak': habit.streak,
        'reminderEnabled': habit.reminderEnabled,
        'reminderHour': habit.reminderHour,
        'reminderMinute': habit.reminderMinute,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<String> getLastOpenDate() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['lastOpenDate'] ?? '';
  }

  static Future<void> saveLastOpenDate(String date) async {
    await _db.collection('users').doc(_uid).set({
      'lastOpenDate': date,
    }, SetOptions(merge: true));
  }

  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> saveDailyLog(
    String habitId,
    String date,
    bool completed,
  ) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .doc(date)
        .set({'completed': completed, 'date': date});
  }

  static Future<Map<String, bool>> getLogsForHabit(String habitId) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('habits')
        .doc(habitId)
        .collection('logs')
        .get();

    return {
      for (final doc in snapshot.docs)
        doc.id: (doc.data()['completed'] as bool? ?? false),
    };
  }
}
