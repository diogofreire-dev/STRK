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
}
