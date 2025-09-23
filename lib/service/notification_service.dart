import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String channelId = 'water_reminder_channel';
  static const String channelName = 'Water Reminder';
  static const String channelDescription = 'Notifications to remind you to drink water';

  static final List<String> reminderMessages = [
    '💧 Time to drink water!',
    '🥤 Stay hydrated! Drink some water',
    '💙 Your body needs water right now',
    '🌊 Hydration time! Take a water break',
    '💦 Don\'t forget to drink water',
    '🚰 Time for your water intake',
    '💧 Keep yourself hydrated!',
  ];

  static Future<void> initialize() async {
    // Request notification permission
    await _requestNotificationPermission();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status != PermissionStatus.granted) {
      print('Notification permission denied');
    }
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.defaultImportance,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showWaterReminderNotification() async {
    final message = reminderMessages[
    DateTime.now().millisecondsSinceEpoch % reminderMessages.length
    ];

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'Water Reminder',
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_consumed',
          'I drank water ✓',
          titleColor: Color.fromARGB(255, 0, 150, 255),
        ),
      ],
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      1001,
      'Water Reminder',
      message,
      platformChannelSpecifics,
      payload: 'water_reminder',
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}