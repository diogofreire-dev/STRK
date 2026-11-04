import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/mascot.dart';

void main() {
  group('MascotMood.forProgress', () {
    test('acompanha o dia', () {
      expect(MascotMood.forProgress(0, 0), MascotMood.feliz);
      expect(MascotMood.forProgress(0, 3), MascotMood.apagada);
      expect(MascotMood.forProgress(1, 3), MascotMood.feliz);
      expect(MascotMood.forProgress(3, 3), MascotMood.festa);
    });
  });

  test('cada estado aponta para um PNG que existe', () {
    for (final m in MascotMood.values) {
      expect(
        File(m.asset).existsSync(),
        isTrue,
        reason: '${m.asset} não existe',
      );
    }
  });

  testWidgets('com "reduzir movimento" a mascote fica parada', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: StrkMascot(mood: MascotMood.feliz)),
      ),
    );
    // Se houvesse animação infinita, isto dava timeout.
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('trocar de estado mostra a pose nova', (tester) async {
    Widget app(MascotMood m) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: StrkMascot(mood: m)),
    );
    await tester.pumpWidget(app(MascotMood.apagada));
    await tester.pumpWidget(app(MascotMood.festa));
    await tester.pumpAndSettle();
    final img = tester.widget<Image>(find.byType(Image));
    expect((img.image as ResizeImage).imageProvider, isA<AssetImage>());
    expect(
      ((img.image as ResizeImage).imageProvider as AssetImage).assetName,
      MascotMood.festa.asset,
    );
  });
}
