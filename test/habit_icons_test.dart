import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/habit_icons.dart';

void main() {
  test('as chaves já gravadas no Firestore continuam a existir', () {
    // Mudar uma destas chaves faria os hábitos antigos virarem estrela.
    expect(habitIcons.map((h) => h.key), [
      'water',
      'fitness',
      'book',
      'meditation',
      'sleep',
      'food',
      'code',
      'music',
      'run',
      'heart',
      'idea',
      'star',
    ]);
  });

  test('cada ícone vai e volta pela chave', () {
    for (final h in habitIcons) {
      expect(keyToIcon(iconToKey(h.icon)), h.icon);
    }
  });

  test('chaves desconhecidas ou nulas caem na estrela', () {
    expect(keyToIcon('nao-existe'), Icons.star_outline_rounded);
    expect(keyToIcon(null), Icons.star_outline_rounded);
    expect(iconToKey(Icons.abc), 'star');
  });
}
