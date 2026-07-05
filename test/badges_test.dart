import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/habit.dart';
import 'package:habit_tracker/badges_screen.dart';

Habit _habit({
  String id = '1',
  String name = 'Hábito',
  IconData icon = Icons.water_drop_outlined,
  bool completedToday = false,
  int streak = 0,
  bool reminderEnabled = false,
  int? reminderHour,
  int? reminderMinute,
}) => Habit(
  id: id,
  name: name,
  icon: icon,
  completedToday: completedToday,
  streak: streak,
  reminderEnabled: reminderEnabled,
  reminderHour: reminderHour,
  reminderMinute: reminderMinute,
);

bool _unlocked(List<HabitBadge> badges, String id) =>
    badges.firstWhere((b) => b.id == id).unlocked;

void main() {
  group('computeBadges — contadores de hábitos', () {
    test('sem hábitos, nenhuma badge de contagem desbloqueada', () {
      final badges = computeBadges([]);
      expect(_unlocked(badges, 'first_habit'), isFalse);
      expect(_unlocked(badges, 'three_habits'), isFalse);
    });

    test('1 hábito desbloqueia "first_habit" mas não "three_habits"', () {
      final badges = computeBadges([_habit()]);
      expect(_unlocked(badges, 'first_habit'), isTrue);
      expect(_unlocked(badges, 'three_habits'), isFalse);
    });

    test('exatamente 3 hábitos desbloqueia "three_habits"', () {
      final habits = List.generate(3, (i) => _habit(id: '$i'));
      final badges = computeBadges(habits);
      expect(_unlocked(badges, 'three_habits'), isTrue);
      expect(_unlocked(badges, 'five_habits'), isFalse);
    });

    test('10 hábitos desbloqueia todas as badges de contagem', () {
      final habits = List.generate(10, (i) => _habit(id: '$i'));
      final badges = computeBadges(habits);
      expect(_unlocked(badges, 'first_habit'), isTrue);
      expect(_unlocked(badges, 'three_habits'), isTrue);
      expect(_unlocked(badges, 'five_habits'), isTrue);
      expect(_unlocked(badges, 'ten_habits'), isTrue);
    });
  });

  group('computeBadges — streaks', () {
    test('streak 2 não desbloqueia "streak_3"', () {
      final badges = computeBadges([_habit(streak: 2)]);
      expect(_unlocked(badges, 'streak_3'), isFalse);
    });

    test('streak exatamente 3 desbloqueia "streak_3"', () {
      final badges = computeBadges([_habit(streak: 3)]);
      expect(_unlocked(badges, 'streak_3'), isTrue);
    });

    test('usa o maior streak entre vários hábitos', () {
      final habits = [_habit(id: '1', streak: 2), _habit(id: '2', streak: 21)];
      final badges = computeBadges(habits);
      expect(_unlocked(badges, 'streak_21'), isTrue);
      expect(_unlocked(badges, 'streak_30'), isFalse);
    });

    test('streak 365 desbloqueia todas as badges de streak', () {
      final badges = computeBadges([_habit(streak: 365)]);
      for (final id in [
        'streak_3',
        'streak_7',
        'streak_14',
        'streak_21',
        'streak_30',
        'streak_60',
        'streak_100',
        'streak_365',
      ]) {
        expect(
          _unlocked(badges, id),
          isTrue,
          reason: 'esperava $id desbloqueado',
        );
      }
    });
  });

  group('computeBadges — progresso diário', () {
    test(
      '"perfect_day" só desbloqueia se todos os hábitos estiverem feitos',
      () {
        final incomplete = [
          _habit(id: '1', completedToday: true),
          _habit(id: '2', completedToday: false),
        ];
        final complete = [
          _habit(id: '1', completedToday: true),
          _habit(id: '2', completedToday: true),
        ];

        expect(_unlocked(computeBadges(incomplete), 'perfect_day'), isFalse);
        expect(_unlocked(computeBadges(complete), 'perfect_day'), isTrue);
      },
    );

    test(
      '"half_done" desbloqueia com metade (arredondado para cima) feita',
      () {
        // 2 de 3 concluídos: ceil(3/2) = 2, por isso deve desbloquear.
        final habits = [
          _habit(id: '1', completedToday: true),
          _habit(id: '2', completedToday: true),
          _habit(id: '3', completedToday: false),
        ];
        expect(_unlocked(computeBadges(habits), 'half_done'), isTrue);
      },
    );

    test('"half_done" não desbloqueia com menos de metade feita', () {
      final habits = [
        _habit(id: '1', completedToday: true),
        _habit(id: '2', completedToday: false),
        _habit(id: '3', completedToday: false),
      ];
      expect(_unlocked(computeBadges(habits), 'half_done'), isFalse);
    });
  });

  group('computeBadges — lembretes', () {
    test('"early_bird" exige um lembrete antes das 7h', () {
      final withEarly = [
        _habit(reminderEnabled: true, reminderHour: 6, reminderMinute: 0),
      ];
      final withLate = [
        _habit(reminderEnabled: true, reminderHour: 8, reminderMinute: 0),
      ];
      expect(_unlocked(computeBadges(withEarly), 'early_bird'), isTrue);
      expect(_unlocked(computeBadges(withLate), 'early_bird'), isFalse);
    });

    test('"night_owl" exige um lembrete às 22h ou mais tarde', () {
      final withNight = [
        _habit(reminderEnabled: true, reminderHour: 22, reminderMinute: 0),
      ];
      final withEvening = [
        _habit(reminderEnabled: true, reminderHour: 21, reminderMinute: 0),
      ];
      expect(_unlocked(computeBadges(withNight), 'night_owl'), isTrue);
      expect(_unlocked(computeBadges(withEvening), 'night_owl'), isFalse);
    });

    test('"all_reminders" exige que todos os hábitos tenham lembrete', () {
      final allSet = [
        _habit(id: '1', reminderEnabled: true),
        _habit(id: '2', reminderEnabled: true),
      ];
      final partial = [
        _habit(id: '1', reminderEnabled: true),
        _habit(id: '2', reminderEnabled: false),
      ];
      expect(_unlocked(computeBadges(allSet), 'all_reminders'), isTrue);
      expect(_unlocked(computeBadges(partial), 'all_reminders'), isFalse);
    });
  });

  group('computeBadges — consistência', () {
    test('"comeback" exige streak > 0 mas não concluído hoje', () {
      final habits = [_habit(streak: 5, completedToday: false)];
      expect(_unlocked(computeBadges(habits), 'comeback'), isTrue);
    });

    test('"consistent" exige que TODOS os hábitos tenham streak >= 3', () {
      final allConsistent = [
        _habit(id: '1', streak: 3),
        _habit(id: '2', streak: 10),
      ];
      final oneBehind = [
        _habit(id: '1', streak: 3),
        _habit(id: '2', streak: 1),
      ];
      expect(_unlocked(computeBadges(allConsistent), 'consistent'), isTrue);
      expect(_unlocked(computeBadges(oneBehind), 'consistent'), isFalse);
    });

    test('"variety" exige hábitos de pelo menos 3 ícones diferentes', () {
      final varied = [
        _habit(id: '1', icon: Icons.water_drop_outlined),
        _habit(id: '2', icon: Icons.fitness_center_outlined),
        _habit(id: '3', icon: Icons.menu_book_outlined),
      ];
      final sameIcon = [
        _habit(id: '1', icon: Icons.water_drop_outlined),
        _habit(id: '2', icon: Icons.water_drop_outlined),
        _habit(id: '3', icon: Icons.water_drop_outlined),
      ];
      expect(_unlocked(computeBadges(varied), 'variety'), isTrue);
      expect(_unlocked(computeBadges(sameIcon), 'variety'), isFalse);
    });
  });

  group('computeBadgesResolved — badge "legend"', () {
    test('nunca desbloqueia com poucos hábitos/streaks', () {
      final badges = computeBadgesResolved([_habit()]);
      expect(_unlocked(badges, 'legend'), isFalse);
    });

    test('desbloqueia quando 20 ou mais outras badges já estão '
        'desbloqueadas', () {
      // Um hábito com tudo ao máximo desbloqueia praticamente todas as
      // badges de streak/contagem/consistência de uma vez.
      final habits = [
        _habit(
          id: '1',
          streak: 365,
          completedToday: true,
          reminderEnabled: true,
          reminderHour: 6,
        ),
        _habit(
          id: '2',
          icon: Icons.fitness_center_outlined,
          streak: 365,
          completedToday: true,
          reminderEnabled: true,
          reminderHour: 22,
        ),
        _habit(
          id: '3',
          icon: Icons.menu_book_outlined,
          streak: 365,
          completedToday: true,
          reminderEnabled: true,
        ),
      ];
      final badges = computeBadgesResolved(habits);
      final unlockedCount = badges.where((b) => b.unlocked).length;
      expect(unlockedCount, greaterThanOrEqualTo(20));
      expect(_unlocked(badges, 'legend'), isTrue);
    });
  });
}
