import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// O que fazer quando o utilizador quer ativar um lembrete.
enum PermissionStep {
  /// Já há permissão: segue.
  granted,

  /// Ainda se pode pedir: explicar primeiro e depois pedir ao sistema.
  explainThenAsk,

  /// O sistema já não deixa pedir: só nas Definições do telemóvel.
  openSettings,
}

class NotificationsService {
  /// Decide o passo seguinte a partir do estado da permissão.
  ///
  /// No iOS, depois de um "Não permitir" o pedido nunca mais aparece. No
  /// Android, o FCM devolve `denied` tanto para "nunca pedido" como para
  /// "recusado", e o sistema ainda deixa pedir de novo, por isso tentamos.
  static PermissionStep stepFor(
    AuthorizationStatus status,
    TargetPlatform platform,
  ) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PermissionStep.granted;
      case AuthorizationStatus.notDetermined:
        return PermissionStep.explainThenAsk;
      case AuthorizationStatus.denied:
        return platform == TargetPlatform.android
            ? PermissionStep.explainThenAsk
            : PermissionStep.openSettings;
    }
  }

  static bool _isGranted(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized ||
      s == AuthorizationStatus.provisional;

  /// Arranque da app. Já NÃO pede permissão: um pedido logo à entrada, sem
  /// contexto, leva muita gente a dizer "não" por reflexo. A permissão é
  /// pedida quando a pessoa ativa o primeiro lembrete (ver
  /// `notification_permission.dart`).
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // O token tem de ser guardado também quando o login acontece depois
      // do arranque (antes só era guardado se já houvesse sessão).
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) _registerTokenIfAllowed();
      });
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      debugPrint('Falha ao iniciar notificações: $e');
    }
  }

  static Future<AuthorizationStatus> currentStatus() async =>
      (await FirebaseMessaging.instance.getNotificationSettings())
          .authorizationStatus;

  /// Mostra o pedido do sistema. Devolve true se a permissão foi dada.
  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted = _isGranted(settings.authorizationStatus);
    if (granted) await _registerTokenIfAllowed();
    return granted;
  }

  static Future<void> _registerTokenIfAllowed() async {
    try {
      if (!_isGranted(await currentStatus())) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('Falha ao registar token FCM: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  static Future<void> removeFcmTokenForCurrentUser() async {
    if (kIsWeb) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
