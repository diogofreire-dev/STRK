import 'package:flutter/material.dart';

/// Um ícone que se pode escolher para um hábito. A [key] é o que fica
/// guardado no Firestore (o `IconData` não é serializável de forma estável).
class HabitIcon {
  final String key;
  final IconData icon;
  final String label;
  const HabitIcon(this.key, this.icon, this.label);
}

/// Catálogo único de ícones. Antes estava copiado em três ficheiros, e
/// acrescentar um ícone num só fazia-o virar estrela ao gravar.
const habitIcons = [
  HabitIcon('water', Icons.water_drop_outlined, 'Água'),
  HabitIcon('fitness', Icons.fitness_center_outlined, 'Exercício'),
  HabitIcon('book', Icons.menu_book_outlined, 'Leitura'),
  HabitIcon('meditation', Icons.self_improvement_outlined, 'Meditação'),
  HabitIcon('sleep', Icons.bedtime_outlined, 'Sono'),
  HabitIcon('food', Icons.restaurant_outlined, 'Dieta'),
  HabitIcon('code', Icons.code_outlined, 'Código'),
  HabitIcon('music', Icons.music_note_outlined, 'Música'),
  HabitIcon('run', Icons.directions_run_outlined, 'Corrida'),
  HabitIcon('heart', Icons.favorite_outline_rounded, 'Saúde'),
  HabitIcon('idea', Icons.lightbulb_outline_rounded, 'Aprender'),
  HabitIcon('star', Icons.star_outline_rounded, 'Outro'),
];

const _fallback = HabitIcon('star', Icons.star_outline_rounded, 'Outro');

String iconToKey(IconData icon) =>
    habitIcons.firstWhere((h) => h.icon == icon, orElse: () => _fallback).key;

IconData keyToIcon(String? key) =>
    habitIcons.firstWhere((h) => h.key == key, orElse: () => _fallback).icon;
