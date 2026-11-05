import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/tappable.dart';
import 'package:habit_tracker/theme_provider.dart';
import 'package:habit_tracker/web_frame.dart';

Widget _framed(Size size) => MediaQuery(
  data: MediaQueryData(size: size),
  child: ThemeProviderScope(
    provider: ThemeProvider(),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: WebFrame(child: SizedBox.expand(key: Key('app'))),
    ),
  ),
);

void main() {
  testWidgets('num ecrã largo a app fica numa coluna de 480px', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_framed(const Size(1400, 900)));
    expect(tester.getSize(find.byKey(const Key('app'))).width, 480);
  });

  testWidgets('num telemóvel a app ocupa o ecrã todo', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_framed(const Size(390, 844)));
    expect(tester.getSize(find.byKey(const Key('app'))).width, 390);
  });

  testWidgets('dentro da coluna o MediaQuery vê a largura da coluna', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late double width;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1400, 900)),
        child: ThemeProviderScope(
          provider: ThemeProvider(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: WebFrame(
              child: Builder(
                builder: (c) {
                  width = MediaQuery.of(c).size.width;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(width, 480);
  });

  group('Tappable', () {
    MouseCursor cursorOf(WidgetTester tester) => tester
        .widget<MouseRegion>(
          find.descendant(
            of: find.byType(Tappable),
            matching: find.byType(MouseRegion),
          ),
        )
        .cursor;

    testWidgets('com ação mostra a mão do rato e chama onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Tappable(onTap: () => taps++, child: const Text('x')),
        ),
      );
      expect(cursorOf(tester), SystemMouseCursors.click);
      await tester.tap(find.text('x'));
      expect(taps, 1);
    });

    testWidgets('sem ação deixa o cursor normal', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Tappable(child: Text('x')),
        ),
      );
      expect(cursorOf(tester), MouseCursor.defer);
    });
  });
}
