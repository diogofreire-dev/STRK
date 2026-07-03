import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/theme_provider.dart';

void main() {
  test('theme provider restores state from a persisted map', () {
    final provider = ThemeProvider();
    provider.applyPersistenceMap({
      'mode': StrkThemeMode.custom.index,
      'accent': const Color(0xFFBF5AF2).value,
      'customBg': CustomBgMode.light.index,
    });

    expect(provider.mode, StrkThemeMode.custom);
    expect(provider.customAccent, const Color(0xFFBF5AF2));
    expect(provider.customBg, CustomBgMode.light);
  });
}
