import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationsService {
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'fcmToken': token,
            }, SetOptions(merge: true));
          }
        }
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          final uid2 = FirebaseAuth.instance.currentUser?.uid;
          if (uid2 != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid2).set({
              'fcmToken': newToken,
            }, SetOptions(merge: true));
          }
        });
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  static Future<void> scheduleDailyReminder(
    String id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    if (kIsWeb) return;
  }

  static Future<void> cancelReminder(String id) async {
    if (kIsWeb) return;
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
