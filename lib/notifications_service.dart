import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler — keep minimal work here.
  // You can expand to handle data-only messages if needed.
}

class NotificationsService {
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'strk_notifications',
    'Strk Notifications',
    description: 'Notifications for Strk habit reminders',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Request notification permissions and handle FCM token lifecycle
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
    } catch (_) {
      // ignore permission/token errors — fall back to local reminders
    }
    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();
    try {
      final String timeZoneName =
          await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // fallback to UTC if timezone lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    // Android channel
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Initialize plugin
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
        // handle tapped notification
      },
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages: display a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      final android = notification.android;
      final title = notification.title ?? '';
      final body = notification.body ?? '';

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon,
      );

      final platformDetails = NotificationDetails(android: androidDetails);

      await _localNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        platformDetails,
      );
    });
  }

  static Future<void> scheduleDailyReminder(
    String id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.zonedSchedule(
      id.hashCode,
      title,
      body,
      scheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelReminder(String id) async {
    await _localNotificationsPlugin.cancel(id.hashCode);
  }

  static Future<void> removeFcmTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
