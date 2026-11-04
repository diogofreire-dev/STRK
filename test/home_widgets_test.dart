import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/habit.dart';
import 'package:habit_tracker/home/celebrations.dart';
import 'package:habit_tracker/home/habit_card.dart';
import 'package:habit_tracker/home/progress_card.dart';
import 'package:habit_tracker/theme_provider.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  final theme = ThemeProvider();

  group('progressMessage', () {
    test('acompanha o dia', () {
      expect(progressMessage(0, 0), contains('Adiciona'));
      expect(progressMessage(0, 4), contains('por fazer'));
      expect(progressMessage(1, 4), contains('arranque'));
      expect(progressMessage(2, 4), contains('metade'));
      expect(progressMessage(3, 4), contains('Só falta um'));
      expect(progressMessage(4, 4), contains('perfeito'));
    });
  });

  group('streakMilestone', () {
    test('só fala nos números redondos', () {
      expect(streakMilestone('Ler', 7), contains('semana'));
      expect(streakMilestone('Ler', 100), contains('100'));
      expect(streakMilestone('Ler', 8), isNull);
      expect(streakMilestone('Ler', 0), isNull);
    });
  });

  group('HabitCard', () {
    Habit habit() => Habit(
      id: '1',
      name: 'Beber água',
      icon: Icons.water_drop_outlined,
      streak: 4,
    );

    testWidgets('tocar chama onToggle', (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        _wrap(
          HabitCard(
            habit: habit(),
            theme: theme,
            onToggle: () => toggles++,
            onLongPress: () {},
            onDismissed: () {},
          ),
        ),
      );
      await tester.tap(find.byType(HabitCard));
      await tester.pumpAndSettle();
      expect(toggles, 1);
    });

    testWidgets('mostra o streak e a chama', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitCard(
            habit: habit(),
            theme: theme,
            onToggle: () {},
            onLongPress: () {},
            onDismissed: () {},
          ),
        ),
      );
      expect(find.text('4 dias'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('1 dia fica no singular', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitCard(
            habit: habit()..streak = 1,
            theme: theme,
            onToggle: () {},
            onLongPress: () {},
            onDismissed: () {},
          ),
        ),
      );
      expect(find.text('1 dia'), findsOneWidget);
      expect(find.text(' seguido'), findsOneWidget);
    });

    testWidgets('o leitor de ecrã ouve nome, streak e estado', (tester) async {
      final handle = tester.ensureSemantics();
      final h = habit()..completedToday = true;
      await tester.pumpWidget(
        _wrap(
          HabitCard(
            habit: h,
            theme: theme,
            onToggle: () {},
            onLongPress: () {},
            onDismissed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Beber água, 4 dias seguidos'),
        ),
        isSemantics(
          label: 'Beber água, 4 dias seguidos',
          hint: 'Toca para marcar, mantém premido para editar',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('ProgressCard anima até ao valor certo', (tester) async {
    await tester.pumpWidget(
      _wrap(ProgressCard(theme: theme, completedCount: 3, totalCount: 4)),
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.75, 0.001));
    expect(find.text('75% feito'), findsOneWidget);
    expect(find.textContaining('Só falta um'), findsOneWidget);
  });

  group('ConfettiOverlay', () {
    Future<void> pumpTrigger(WidgetTester tester, int t, bool reduce) =>
        tester.pumpWidget(
          _wrap(
            ConfettiOverlay(trigger: t, colors: const [Colors.red]),
            reduceMotion: reduce,
          ),
        );

    testWidgets('dispara quando o trigger muda e depois some', (tester) async {
      await pumpTrigger(tester, 0, false);
      await pumpTrigger(tester, 1, false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.descendant(
          of: find.byType(ConfettiOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(ConfettiOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('com "reduzir movimento" não mostra nada', (tester) async {
      await pumpTrigger(tester, 0, true);
      await pumpTrigger(tester, 1, true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.descendant(
          of: find.byType(ConfettiOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });
}
