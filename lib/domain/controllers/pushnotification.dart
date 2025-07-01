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
import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/main.dart';

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;
  BuildContext? _context;

  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  Future<void> init() async {
    // Request permission for iOS
    if (_context != null && Theme.of(_context!).platform == TargetPlatform.iOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTerminatedStateNotification);
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("Received foreground message");
    _showNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
    );
  }

  void _handleTerminatedStateNotification(RemoteMessage message) {
    print("Message opened app");
    // Handle navigation or other actions when app is opened from notification
  }

  void _showNotification({
    required String title,
    required String body,
  }) {
    if (_isShowing) {
      _overlayEntry?.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // Handle tap to return to recording page
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          body,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (navigatorKey.currentContext != null) {
      Overlay.of(navigatorKey.currentContext!).insert(_overlayEntry!);
      _isShowing = true;
    }
  }

  void hideNotification() {
    if (_isShowing) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}
////////////////////
// In your logout method
//await PushNotifications().deleteDeviceToken();
// Proceed with rest of logout logic