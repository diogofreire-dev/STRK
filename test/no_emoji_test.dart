import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// A STRK usa ícones, não emojis (os emojis mudam de aspeto de telemóvel
/// para telemóvel e não seguem a cor do tema). Este teste impede que
/// voltem a entrar no código sem darmos por isso.
void main() {
  test('não há emojis em lib/', () {
    final emoji = RegExp(
      '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2728}\u{2705}]',
      unicode: true,
    );
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (emoji.hasMatch(lines[i])) found.add('${f.path}:${i + 1}');
      }
    }
    expect(
      found,
      isEmpty,
      reason: 'Emojis encontrados em:\n${found.join('\n')}',
    );
  });
}
