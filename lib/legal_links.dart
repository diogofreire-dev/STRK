import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Endereço público da STRK. As páginas legais (web/privacidade.html e
/// web/termos.html) são publicadas junto com a app web.
const kSiteUrl = String.fromEnvironment(
  'STRK_SITE_URL',
  defaultValue: 'https://strk.diogofreire.is-a.dev',
);

/// Na web abre a página do próprio site (funciona também em testes locais);
/// nas apps nativas usa o endereço público.
Uri legalUri(String page) =>
    kIsWeb ? Uri.base.resolve(page) : Uri.parse('$kSiteUrl/$page');

Future<void> openLegalPage(BuildContext context, String page) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(
    legalUri(page),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir a página.')),
    );
  }
}
