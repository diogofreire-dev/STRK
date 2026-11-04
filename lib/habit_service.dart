import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'habit.dart';

class HabitService {
  static final _db = FirebaseFirestore.instance;

  // Cached birthday for birthday banner (loaded on app start via loadUserProfile)
  static DateTime? cachedBirthday;

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

  // ── Habits ─────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _toMap(Habit habit) => {
    'id': habit.id,
    'name': habit.name,
    'icon': _iconToKey(habit.icon),
    'completedToday': habit.completedToday,
    'streak': habit.streak,
    'lastCompletedDate': habit.lastCompletedDate,
    'reminderEnabled': habit.reminderEnabled,
    'reminderHour': habit.reminderHour,
    'reminderMinute': habit.reminderMinute,
    'lastUpdated': FieldValue.serverTimestamp(),
  };

  static Future<void> saveHabit(Habit habit) async {
    await _habitsRef.doc(habit.id).set(_toMap(habit));
  }

  /// Apaga o hábito e os seus logs diários. O Firestore não apaga
  /// subcoleções quando se apaga um documento, por isso os logs têm de ser
  /// apagados à mão (em batches, que estão limitados a 500 operações).
  static Future<void> deleteHabit(String id) async {
    final habitRef = _habitsRef.doc(id);
    final logs = await habitRef.collection('logs').get();
    final refs = [...logs.docs.map((d) => d.reference), habitRef];
    for (var i = 0; i < refs.length; i += 500) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(500)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  /// Carrega os hábitos do utilizador. [lastOpenDate] só é usado para
  /// migrar documentos antigos que ainda não têm `lastCompletedDate`.
  static Future<List<Habit>> loadHabits({String lastOpenDate = ''}) async {
    final snapshot = await _habitsRef.orderBy('lastUpdated').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final completedToday = data['completedToday'] as bool? ?? false;
      final streak = data['streak'] as int? ?? 0;
      return Habit(
        id: data['id'],
        name: data['name'],
        icon: _keyToIcon(data['icon']),
        completedToday: completedToday,
        streak: streak,
        lastCompletedDate: data.containsKey('lastCompletedDate')
            ? data['lastCompletedDate'] as String?
            : legacyLastCompletedDate(
                completedToday: completedToday,
                streak: streak,
                lastOpenDate: lastOpenDate,
              ),
        reminderEnabled: data['reminderEnabled'] ?? false,
        reminderHour: data['reminderHour'] as int?,
        reminderMinute: data['reminderMinute'] as int?,
      );
    }).toList();
  }

  /// Deduz a última conclusão de um hábito gravado antes de existir
  /// `lastCompletedDate`. Nessa versão, `completedToday` dizia respeito ao
  /// dia `lastOpenDate`; se não estava feito mas tinha streak, a sequência
  /// terminava no dia anterior.
  static String? legacyLastCompletedDate({
    required bool completedToday,
    required int streak,
    required String lastOpenDate,
  }) {
    final opened = DateTime.tryParse(lastOpenDate);
    if (opened == null) return null;
    if (completedToday) return dateKey(opened);
    return streak > 0 ? dateKey(previousDay(opened)) : null;
  }

  static Future<void> saveAllHabits(List<Habit> habits) async {
    final batch = _db.batch();
    for (final habit in habits) {
      batch.set(_habitsRef.doc(habit.id), _toMap(habit));
    }
    await batch.commit();
  }

  // ── Last open date ─────────────────────────────────────────────────────────

  static Future<String> getLastOpenDate() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['lastOpenDate'] ?? '';
  }

  static Future<void> saveLastOpenDate(String date) async {
    await _db.collection('users').doc(_uid).set({
      'lastOpenDate': date,
    }, SetOptions(merge: true));
  }

  static String todayString() => dateKey(DateTime.now());

  // ── Daily logs ─────────────────────────────────────────────────────────────

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

  // ── User profile (birthday) ────────────────────────────────────────────────

  /// Loads the user profile from Firestore and caches the birthday locally.
  /// Call this once after the user is authenticated (e.g. inside _loadHabits).
  static Future<void> loadUserProfile() async {
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      final data = doc.data();
      if (data == null) return;
      final bdString = data['birthday'] as String?;
      if (bdString != null) {
        cachedBirthday = DateTime.tryParse(bdString);
      }
    } catch (_) {}
  }

  /// Saves the birthday to Firestore in ISO format (YYYY-MM-DD).
  static Future<void> saveBirthday(DateTime date) async {
    final iso = dateKey(date);
    await _db.collection('users').doc(_uid).set({
      'birthday': iso,
    }, SetOptions(merge: true));
    cachedBirthday = date;
  }

  /// Removes the birthday from Firestore and clears the cache.
  static Future<void> removeBirthday() async {
    await _db.collection('users').doc(_uid).set({
      'birthday': FieldValue.delete(),
    }, SetOptions(merge: true));
    cachedBirthday = null;
  }
}
