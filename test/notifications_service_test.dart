import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/notifications_service.dart';

void main() {
  PermissionStep step(AuthorizationStatus s, TargetPlatform p) =>
      NotificationsService.stepFor(s, p);

  test('com permissão (normal ou provisória) segue em frente', () {
    for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
      expect(step(AuthorizationStatus.authorized, p), PermissionStep.granted);
      expect(step(AuthorizationStatus.provisional, p), PermissionStep.granted);
    }
  });

  test('nunca pedido: explica e pede', () {
    expect(
      step(AuthorizationStatus.notDetermined, TargetPlatform.iOS),
      PermissionStep.explainThenAsk,
    );
  });

  test('iOS depois de recusar: só nas Definições', () {
    expect(
      step(AuthorizationStatus.denied, TargetPlatform.iOS),
      PermissionStep.openSettings,
    );
    expect(
      step(AuthorizationStatus.denied, TargetPlatform.macOS),
      PermissionStep.openSettings,
    );
  });

  test('Android com "denied" ainda tenta pedir', () {
    // No Android o FCM não distingue "nunca pedido" de "recusado".
    expect(
      step(AuthorizationStatus.denied, TargetPlatform.android),
      PermissionStep.explainThenAsk,
    );
  });
}
