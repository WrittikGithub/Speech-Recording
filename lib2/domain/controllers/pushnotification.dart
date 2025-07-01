// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class Pushnotifications {
//   static final _firebaseMessaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin
//       _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   //request notification permission
//   static Future init() async {
//     await _firebaseMessaging.requestPermission(
//         alert: true,
//         announcement: true,
//         badge: true,
//         carPlay: false,
//         criticalAlert: true,
//         provisional: false,
//         sound: true);
//     //get the device fcm token
//     final token = await _firebaseMessaging.getToken();
//     debugPrint("device token : $token");

//   }

// //store device token
//   static Future getDevicetoken() async {
//     final token = await _firebaseMessaging.getToken();
//    // also save if token changes
//     _firebaseMessaging.onTokenRefresh.listen((event) async {

//     });
//   }

//   //initialisw local notifications
//   static Future localNotiInit() async {
//     //initialize the plugin. app_icon needs to be a added as a drawable resource
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//   final DarwinInitializationSettings initializationSettingsDarvin =
//         DarwinInitializationSettings(
//       onDidReceiveLocalNotification: (int id,String? title,String? body, payload) => null,
//     );
//     final LinuxInitializationSettings initializationSettingsLinux =
//         LinuxInitializationSettings(defaultActionName: 'Open notifications');
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//             android: initializationSettingsAndroid,
//             iOS: initializationSettingsDarvin,
//             linux: initializationSettingsLinux);
//     //request notification permission for android 13 or above
//     _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()!
//         .requestNotificationsPermission();
//     _flutterLocalNotificationsPlugin.initialize(initializationSettings,
//         onDidReceiveNotificationResponse: onNotificationTap,
//         onDidReceiveBackgroundNotificationResponse: onNotificationTap);
//   }

//   //on tap local notification is foreground
//   static void onNotificationTap(NotificationResponse notificationResponse) {
//     //navigate message page
//   }
//   //show simple notification
//   static Future showSimpleNotification(
//       {required String title,
//       required String body,
//       required String payload}) async {
//     const AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails('your channel id', 'your channel name',
//             channelDescription: 'your channel description',
//             importance: Importance.max,
//             priority: Priority.high,
//             ticker: 'ticker');
//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidNotificationDetails);
//     await _flutterLocalNotificationsPlugin
//         .show(0, title, body, notificationDetails, payload: payload);
//   }
// }
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotifications {
  // Singleton instance
  static final PushNotifications _instance = PushNotifications._internal();
  factory PushNotifications() => _instance;
  PushNotifications._internal();

  // Firebase Messaging and Local Notifications instances
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel details
  static const AndroidNotificationChannel _androidNotificationChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Initialize push notifications
  Future<void> init() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _requestPermissions();

      // Configure notification settings based on permission status
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get device token
        await _getDeviceToken();

        // Initialize local notifications
        await _initLocalNotifications();

        // Listen to various notification states
        _setupNotificationListeners();
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  // Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: false,
      carPlay: false,
    );
  }

  // Get and handle device token
  Future<void> _getDeviceToken() async {
    try {
      // Get current token
      final token = await _firebaseMessaging.getToken();
      debugPrint('Device Token: $token');

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('Token Refreshed: $newToken');
        // TODO: Send the new token to your server
      });
    } catch (e) {
      debugPrint('Error getting device token: $e');
    }
  }

  // Delete device token on logout
  Future<void> deleteDeviceToken() async {
    try {
      // Delete the token from Firebase
      await _firebaseMessaging.deleteToken();
      
      // Cancel all pending notifications
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      // Remove all notification channels (Android only)
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.deleteNotificationChannel(
          _androidNotificationChannel.id,
        );
      }
      
      debugPrint('Device token deleted successfully');
    } catch (e) {
      debugPrint('Error deleting device token: $e');
      rethrow;
    }
  }

  // Initialize local notifications
  Future<void> _initLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    // Initialize settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    // Create notification channel for Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidNotificationChannel);

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Setup notification listeners
  void _setupNotificationListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message');
      _handleForegroundMessage(message);
    });

    // Handle background/terminated state message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app');
      _handleTerminatedStateNotification(message);
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    // Android notification details
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      _androidNotificationChannel.id,
      _androidNotificationChannel.name,
      channelDescription: _androidNotificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    // Notification details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Show the notification
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle iOS foreground notifications
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('Received iOS local notification');
    // Handle iOS specific foreground notifications
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse notificationResponse) {
    debugPrint('Notification tapped');
    // TODO: Implement navigation logic
    // Example:
    // final payload = notificationResponse.payload;
    // Navigator.pushNamed(context, '/notification-detail', arguments: payload);
  }

  // Background message handler (static method)
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    debugPrint('Handling background message');
    // Handle background messages if needed
  }

  void _handleTerminatedStateNotification(RemoteMessage message) {
    // Extract relevant information from the message
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      debugPrint('Notification Title: ${notification.title}');
      debugPrint('Notification Body: ${notification.body}');
    }
  }
}
////////////////////
// In your logout method
//await PushNotifications().deleteDeviceToken();
// Proceed with rest of logout logic