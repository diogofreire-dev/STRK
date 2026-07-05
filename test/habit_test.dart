import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/habit.dart';
import 'package:habit_tracker/habit_service.dart';

void main() {
  test('Habit model default values', () {
    final habit = Habit(
      id: '1',
      name: 'Beber água',
      icon: Icons.water_drop_outlined,
    );

    expect(habit.id, '1');
    expect(habit.name, 'Beber água');
    expect(habit.completedToday, isFalse);
    expect(habit.streak, 0);
  });

  test('todayString returns formatted date', () {
    final formatted = HabitService.todayString();
    expect(formatted, matches(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$'));
  });

  group('Habit.toggleCompletion', () {
    test('marking as done increments the streak', () {
      final habit = Habit(
        id: '1',
        name: 'Beber água',
        icon: Icons.water_drop_outlined,
        streak: 3,
      );

      habit.toggleCompletion();

      expect(habit.completedToday, isTrue);
      expect(habit.streak, 4);
    });

    test('unmarking a done habit decrements the streak', () {
      final habit = Habit(
        id: '1',
        name: 'Beber água',
        icon: Icons.water_drop_outlined,
        completedToday: true,
        streak: 4,
      );

      habit.toggleCompletion();

      expect(habit.completedToday, isFalse);
      expect(habit.streak, 3);
    });

    test('toggling twice returns to the original state', () {
      final habit = Habit(
        id: '1',
        name: 'Beber água',
        icon: Icons.water_drop_outlined,
        streak: 5,
      );

      habit.toggleCompletion();
      habit.toggleCompletion();

      expect(habit.completedToday, isFalse);
      expect(habit.streak, 5);
    });
  });

  group('HabitService.applyDailyReset', () {
    test('resets streak to 0 for habits not completed yesterday', () {
      final habits = [
        Habit(
          id: '1',
          name: 'Beber água',
          icon: Icons.water_drop_outlined,
          streak: 10,
          completedToday: false,
        ),
      ];

      HabitService.applyDailyReset(habits);

      expect(habits.first.streak, 0);
      expect(habits.first.completedToday, isFalse);
    });

    test('preserves streak for habits completed yesterday but resets '
        'completedToday for the new day', () {
      final habits = [
        Habit(
          id: '1',
          name: 'Beber água',
          icon: Icons.water_drop_outlined,
          streak: 10,
          completedToday: true,
        ),
      ];

      HabitService.applyDailyReset(habits);

      expect(habits.first.streak, 10);
      expect(habits.first.completedToday, isFalse);
    });

    test('handles a mix of completed and uncompleted habits independently', () {
      final habits = [
        Habit(
          id: '1',
          name: 'Concluído',
          icon: Icons.water_drop_outlined,
          streak: 8,
          completedToday: true,
        ),
        Habit(
          id: '2',
          name: 'Não concluído',
          icon: Icons.fitness_center_outlined,
          streak: 8,
          completedToday: false,
        ),
      ];

      HabitService.applyDailyReset(habits);

      expect(habits[0].streak, 8);
      expect(habits[1].streak, 0);
      expect(habits.every((h) => !h.completedToday), isTrue);
    });

    test('does nothing on an empty list', () {
      final habits = <Habit>[];
      expect(() => HabitService.applyDailyReset(habits), returnsNormally);
    });
  });
}
