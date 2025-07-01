import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await AwesomeNotifications().initialize(
      null, // no icon for now, will use app icon
      [
        NotificationChannel(
          channelKey: 'recording_channel',
          channelName: 'Recording',
          channelDescription: 'Shows recording status',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          importance: NotificationImportance.High,
          playSound: false,
          enableVibration: false,
          locked: true, // Makes notification persistent/ongoing
        )
      ],
    );

    _isInitialized = true;
  }

  Future<void> showRecordingNotification(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'recording_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.red,
        backgroundColor: Colors.red,
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
        locked: true, // Makes notification persistent/ongoing
        autoDismissible: false,
      ),
    );
  }

  Future<void> stopNotificationService() async {
    if (!_isInitialized) return;
    await AwesomeNotifications().cancel(0);
  }
} 