import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// no Flutter material imports required here

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler — keep minimal work here.
  // You can expand to handle data-only messages if needed.
}

class NotificationsService {
  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'strk_notifications',
    'Strk Notifications',
    description: 'Notifications for Strk habit reminders',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Android channel
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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

    await _localNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {
      // handle tapped notification
    });

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
}
