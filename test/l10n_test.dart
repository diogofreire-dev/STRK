import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/l10n.dart';
import 'package:intl/intl.dart';

Widget _app(Widget home) => MaterialApp(
  locale: strkLocale,
  supportedLocales: strkSupportedLocales,
  localizationsDelegates: strkLocalizationsDelegates,
  home: home,
);

void main() {
  testWidgets('o seletor de hora aparece em português', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    showTimePicker(
      context: ctx,
      initialTime: const TimeOfDay(hour: 20, minute: 30),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('as horas usam o formato de 24h', (tester) async {
    late String formatted;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (c) {
            formatted = const TimeOfDay(hour: 20, minute: 5).format(c);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(formatted, '20:05');
  });

  testWidgets('os meses vêm em português', (tester) async {
    // Os delegates do Flutter carregam os dados de datas do intl para pt_PT.
    await tester.pumpWidget(_app(const SizedBox()));
    expect(
      DateFormat("d 'de' MMMM", 'pt_PT').format(DateTime(2004, 3, 15)),
      '15 de março',
    );
  });
}
