import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/legal_links.dart';

void main() {
  test('nas apps nativas as páginas apontam para o site público', () {
    expect(
      legalUri('privacidade.html').toString(),
      '$kSiteUrl/privacidade.html',
    );
    expect(kSiteUrl, startsWith('https://'));
  });

  group('páginas legais', () {
    final privacidade = File('web/privacidade.html').readAsStringSync();
    final termos = File('web/termos.html').readAsStringSync();

    test('estão em português e ligam uma à outra', () {
      for (final page in [privacidade, termos]) {
        expect(page, contains('<html lang="pt-PT">'));
      }
      expect(privacidade, contains('href="termos.html"'));
      expect(termos, contains('href="privacidade.html"'));
    });

    test('o contacto é o mesmo nas duas', () {
      const email = 'diogoffreire1@gmail.com';
      expect(privacidade, contains(email));
      expect(termos, contains(email));
    });

    test('não ficaram textos de exemplo por preencher', () {
      for (final page in [privacidade, termos]) {
        expect(
          page,
          isNot(
            matches(
              RegExp(r'TODO|COLA_AQUI|lorem|\[.*?\]', caseSensitive: false),
            ),
          ),
        );
      }
    });

    test('a privacidade explica como apagar a conta e onde reclamar', () {
      expect(privacidade, contains('Eliminar conta'));
      expect(privacidade, contains('CNPD'));
      expect(privacidade, contains('europe-west1'));
    });
  });
}
