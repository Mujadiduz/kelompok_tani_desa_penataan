import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotification();
    _listenForegroundMessage();
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

  static void _listenForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      final title =
          notification?.title ??
          message.data['title'] ??
          'Kelompok Tani Desa Penataan';

      final body =
          notification?.body ?? message.data['body'] ?? 'Ada notifikasi baru';

      showLocalNotification(title: title, body: body);
    });
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }

  static Future<void> saveTokenForUser(String nik) async {
    if (nik.trim().isEmpty) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _db.child('anggota/$nik').update({
      'fcm_token': token,
      'updated_token_at': DateTime.now().toIso8601String(),
    });

    await _db.child('fcm_tokens/$nik/$token').set({
      'nik': nik,
      'token': token,
      'platform': 'android',
      'updated_at': DateTime.now().toIso8601String(),
    });

    _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isEmpty) return;

      await _db.child('anggota/$nik').update({
        'fcm_token': newToken,
        'updated_token_at': DateTime.now().toIso8601String(),
      });

      await _db.child('fcm_tokens/$nik/$newToken').set({
        'nik': nik,
        'token': newToken,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
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
