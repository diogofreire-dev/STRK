import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/auth_screen.dart';
import 'package:habit_tracker/theme_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// url_launcher falso: em vez de abrir o browser, regista o que lhe pedem.
class _FakeLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

void main() {
  testWidgets('no registo, "Termos" e "Política de privacidade" abrem as '
      'páginas certas', (tester) async {
    final fake = _FakeLauncher();
    UrlLauncherPlatform.instance = fake;
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ThemeProviderScope(
        provider: ThemeProvider(),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // O aviso só aparece no modo de registo.
    expect(find.text('Termos'), findsNothing);
    await tester.tap(find.text('Regista-te'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Termos'));
    await tester.pump();
    await tester.tap(find.text('Política de privacidade'));
    await tester.pump();

    expect(fake.opened, hasLength(2));
    expect(fake.opened[0], endsWith('/termos.html'));
    expect(fake.opened[1], endsWith('/privacidade.html'));
  });
}
