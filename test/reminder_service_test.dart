import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/habit.dart';
import 'package:habit_tracker/reminder_service.dart';

Habit _habit({
  String id = '1',
  bool reminder = true,
  int hour = 20,
  int minute = 0,
  bool completedToday = false,
  int streak = 0,
}) => Habit(
  id: id,
  name: 'Ler',
  icon: Icons.menu_book_outlined,
  completedToday: completedToday,
  streak: streak,
  reminderEnabled: reminder,
  reminderHour: reminder ? hour : null,
  reminderMinute: reminder ? minute : null,
);

void main() {
  final morning = DateTime(2026, 3, 10, 9);

  group('ReminderService.plan', () {
    test('sem lembretes ativos não agenda nada', () {
      expect(ReminderService.plan([_habit(reminder: false)], morning), isEmpty);
    });

    test('agenda hoje e os próximos 6 dias à hora escolhida', () {
      final plan = ReminderService.plan([
        _habit(hour: 20, minute: 30),
      ], morning);
      expect(plan, hasLength(7));
      expect(plan.first.when, DateTime(2026, 3, 10, 20, 30));
      expect(plan.last.when, DateTime(2026, 3, 16, 20, 30));
    });

    test('hábito já feito hoje salta o lembrete de hoje', () {
      final plan = ReminderService.plan([
        _habit(completedToday: true),
      ], morning);
      expect(plan, hasLength(6));
      expect(plan.first.when, DateTime(2026, 3, 11, 20));
    });

    test('se a hora de hoje já passou, começa amanhã', () {
      final plan = ReminderService.plan([
        _habit(hour: 8),
      ], DateTime(2026, 3, 10, 8, 0));
      expect(plan.first.when, DateTime(2026, 3, 11, 8));
    });

    test('nunca passa o limite de notificações pendentes do iOS', () {
      final habits = [for (var i = 0; i < 20; i++) _habit(id: 'h$i')];
      final plan = ReminderService.plan(habits, morning);
      expect(plan.length, lessThanOrEqualTo(ReminderService.maxPending));
      // 60 ~/ 20 = 3 dias por hábito.
      expect(plan.where((r) => r.title == 'Ler'), hasLength(60));
    });

    test('com mais hábitos do que o limite, ficam os mais próximos', () {
      final habits = [
        for (var i = 0; i < 80; i++) _habit(id: 'h$i', hour: i < 70 ? 21 : 7),
      ];
      final plan = ReminderService.plan(habits, morning);
      expect(plan, hasLength(ReminderService.maxPending));
      // Os de hoje às 21h (70) vêm antes dos de amanhã às 7h.
      expect(plan.every((r) => r.when == DateTime(2026, 3, 10, 21)), isTrue);
    });

    test('o texto de hoje fala do streak em risco', () {
      final plan = ReminderService.plan([_habit(streak: 5)], morning);
      expect(plan.first.body, contains('5 dias'));
      expect(plan[1].body, isNot(contains('dias seguidos')));
    });

    test('a mudança de mês não salta dias', () {
      final plan = ReminderService.plan([_habit()], DateTime(2026, 1, 30, 9));
      expect(plan.map((r) => r.when.day), [30, 31, 1, 2, 3, 4, 5]);
    });
  });

  group('ReminderService.notificationId', () {
    test('é estável e diferente por dia', () {
      final a = ReminderService.notificationId('1730000000000', 0);
      expect(ReminderService.notificationId('1730000000000', 0), a);
      expect(ReminderService.notificationId('1730000000000', 1), a + 1);
    });

    test('cabe num int de 32 bits (exigido pelo Android)', () {
      for (final id in ['1', 'abc', '9999999999999', 'zzzzzzzzzzzzzzzz']) {
        expect(
          ReminderService.notificationId(id, 9),
          inInclusiveRange(0, 0x7FFFFFFF),
        );
      }
    });

    test('hábitos diferentes têm ids diferentes', () {
      final ids = {
        for (var i = 0; i < 500; i++)
          ReminderService.notificationId('${1730000000000 + i}', 0),
      };
      expect(ids, hasLength(500));
    });
  });
}
