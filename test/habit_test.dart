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

  group('Habit.toggleCompletion com datas', () {
    final now = DateTime(2026, 3, 10, 21);

    test('marcar guarda hoje como última conclusão', () {
      final habit = _habit(streak: 2, lastCompletedDate: '2026-03-09');
      habit.toggleCompletion(now: now);
      expect(habit.lastCompletedDate, '2026-03-10');
      expect(habit.streak, 3);
    });

    test('desmarcar com streak restante volta a ontem', () {
      final habit = _habit(
        streak: 3,
        completedToday: true,
        lastCompletedDate: '2026-03-10',
      );
      habit.toggleCompletion(now: now);
      expect(habit.lastCompletedDate, '2026-03-09');
      expect(habit.streak, 2);
    });

    test('desmarcar o primeiro dia limpa a data e não fica negativo', () {
      final habit = _habit(
        streak: 1,
        completedToday: true,
        lastCompletedDate: '2026-03-10',
      );
      habit.toggleCompletion(now: now);
      expect(habit.lastCompletedDate, isNull);
      expect(habit.streak, 0);
    });
  });

  group('Habit.refreshForDay', () {
    final now = DateTime(2026, 3, 10, 9);

    test('concluído hoje continua feito e mantém o streak', () {
      final habit = _habit(streak: 4, lastCompletedDate: '2026-03-10');
      habit.refreshForDay(now);
      expect(habit.completedToday, isTrue);
      expect(habit.streak, 4);
    });

    test('concluído ontem: ainda não feito hoje, mas o streak continua', () {
      final habit = _habit(
        streak: 4,
        completedToday: true,
        lastCompletedDate: '2026-03-09',
      );
      habit.refreshForDay(now);
      expect(habit.completedToday, isFalse);
      expect(habit.streak, 4);
    });

    test('falhou um dia inteiro: o streak quebra', () {
      final habit = _habit(
        streak: 12,
        completedToday: true,
        lastCompletedDate: '2026-03-08',
      );
      habit.refreshForDay(now);
      expect(habit.completedToday, isFalse);
      expect(habit.streak, 0);
    });

    test('nunca concluído fica a zero', () {
      final habit = _habit(streak: 0);
      habit.refreshForDay(now);
      expect(habit.streak, 0);
      expect(habit.completedToday, isFalse);
    });

    test('ontem atravessa a mudança de ano', () {
      final habit = _habit(streak: 30, lastCompletedDate: '2025-12-31');
      habit.refreshForDay(DateTime(2026, 1, 1, 8));
      expect(habit.streak, 30);
    });

    test('ontem atravessa a mudança para a hora de verão', () {
      // Em Portugal, 2026-03-29 tem só 23 horas.
      final habit = _habit(streak: 5, lastCompletedDate: '2026-03-29');
      habit.refreshForDay(DateTime(2026, 3, 30, 0, 30));
      expect(habit.streak, 5);
    });
  });

  group('HabitService.legacyLastCompletedDate', () {
    test('feito no dia da última abertura', () {
      expect(
        HabitService.legacyLastCompletedDate(
          completedToday: true,
          streak: 3,
          lastOpenDate: '2026-03-10',
        ),
        '2026-03-10',
      );
    });

    test('não feito mas com streak: a sequência acabava na véspera', () {
      expect(
        HabitService.legacyLastCompletedDate(
          completedToday: false,
          streak: 3,
          lastOpenDate: '2026-03-01',
        ),
        '2026-02-28',
      );
    });

    test('sem streak ou sem data, não há última conclusão', () {
      expect(
        HabitService.legacyLastCompletedDate(
          completedToday: false,
          streak: 0,
          lastOpenDate: '2026-03-10',
        ),
        isNull,
      );
      expect(
        HabitService.legacyLastCompletedDate(
          completedToday: true,
          streak: 2,
          lastOpenDate: '',
        ),
        isNull,
      );
    });
  });
}

Habit _habit({
  int streak = 0,
  bool completedToday = false,
  String? lastCompletedDate,
}) => Habit(
  id: '1',
  name: 'Beber água',
  icon: Icons.water_drop_outlined,
  streak: streak,
  completedToday: completedToday,
  lastCompletedDate: lastCompletedDate,
);
