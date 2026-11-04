import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/home/tab_bar.dart';
import 'package:habit_tracker/theme_provider.dart';
import 'package:habit_tracker/transitions.dart';

Widget _app(Widget child, {bool reduce = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('DirectionalTabSwitcher troca o conteúdo', (tester) async {
    Widget at(int i) =>
        _app(DirectionalTabSwitcher(index: i, child: Text('separador $i')));
    await tester.pumpWidget(at(0));
    await tester.pumpWidget(at(2));
    // A meio da transição estão os dois no ecrã.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('separador 0'), findsOneWidget);
    expect(find.text('separador 2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('separador 0'), findsNothing);
    expect(find.text('separador 2'), findsOneWidget);
  });

  testWidgets('com "reduzir movimento" a troca é imediata', (tester) async {
    Widget at(int i) => _app(
      DirectionalTabSwitcher(index: i, child: Text('separador $i')),
      reduce: true,
    );
    await tester.pumpWidget(at(0));
    await tester.pumpWidget(at(1));
    await tester.pump();
    expect(find.text('separador 0'), findsNothing);
  });

  testWidgets('StaggeredEntrance acaba visível', (tester) async {
    await tester.pumpWidget(
      _app(const StaggeredEntrance(index: 3, child: Text('cartão'))),
    );
    var fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(StaggeredEntrance),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(StaggeredEntrance),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('sheetRoute abre e fecha a página', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.push(context, sheetRoute(const Text('folha'))),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('folha'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('folha'), findsNothing);
  });

  testWidgets('StrkTabBar avisa o separador tocado', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _app(
        StrkTabBar(
          currentTab: 0,
          theme: ThemeProvider(),
          onTabSelected: (i) => tapped = i,
        ),
      ),
    );
    await tester.tap(find.text('Stats'));
    expect(tapped, 2);
    // Tocar no separador ativo não faz nada.
    tapped = null;
    await tester.tap(find.text('Hoje'));
    expect(tapped, isNull);
  });
}
