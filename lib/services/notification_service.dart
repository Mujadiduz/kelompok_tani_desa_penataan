import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotification();
    await _listenForegroundMessage();
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _initLocalNotification() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);
  }

  static Future<void> _listenForegroundMessage() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification == null) return;

      showLocalNotification(
        title: notification.title ?? 'Kelompok Tani Desa Penataan',
        body: notification.body ?? '',
      );
    });
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kelompok_tani_channel',
      'Kelompok Tani Notification',
      channelDescription: 'Notifikasi aplikasi kelompok tani',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }
}
