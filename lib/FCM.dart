import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Settings/notifications_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialize FCM & Local Notifications
  static Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    await _saveTokenToFirestore(token);

    // Define and register the Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Must match the one used in show()
      'High Importance Notifications',
      description: 'Used for important notifications',
      importance: Importance.max,
    );

    // Create the notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped (from foreground or background)
        final payload = response.payload;
        if (payload != null) {
          print("Notification clicked with payload: $payload");
          // Optionally: parse and route based on payload
        }
      },
    );

    // Foreground notification handler
    FirebaseMessaging.onMessage.listen(showNotification);

    // When user taps on notification (background/opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Background handler (needed for terminated case)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    await FirebaseFirestore.instance.collection('fcm_tokens').doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Show notification when app is in foreground
  static Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'New Update',
      message.notification?.body ?? 'Check the latest updates',
      platformChannelSpecifics,
      payload: message.data['type'] ?? '',
    );
  }

  // Handle notification click (navigate to screen)
  static void _handleNotificationClick(RemoteMessage message) {
    final type = message.data['type'];
    final id = message.data['id'];

    if (type == 'news') {
      // Navigate to News Screen
    } else if (type == 'ta_application') {
      // Navigate to TA Application Screen
    }
  }

  static Future<void> toggleNotifications(bool enabled) async {
    await NotificationPreferences.setNotificationsEnabled(enabled);

    if (enabled) {
      // Re-register FCM token if enabled
      String? token = await _firebaseMessaging.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    } else {
      // Delete token if disabled
      await _deleteTokenFromFirestore();
      await _flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  // Helper to delete FCM token from Firestore
  static Future<void> _deleteTokenFromFirestore() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .delete();
    }
  }

  // Background handler (must be top-level)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;

    if (enabled) {
      await showNotification(message);
    }
  }
}
