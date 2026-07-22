import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_helper.dart';

class NotificationService {
  NotificationService._();

  static const String _databaseUrl =
      'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const String _channelId =
      'kelompok_tani_local_channel';

  static const String _channelName =
      'Notifikasi TaniGo';

  static const String _channelDescription =
      'Notifikasi lokal aplikasi TaniGo';

  static const String _shownPrefix =
      'tanigo_shown_notification_ids_';

  static const int _maxShownIds = 500;

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseDatabase _db =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  );

  static final List<_QueuedNotification> _queue = [];

  static final Set<String> _queuedIds = {};

  static final Set<String> _knownFirebaseIds = {};

  static final Map<String, Set<String>> _shownByScope = {};

  static StreamSubscription<DatabaseEvent>?
      _notificationSubscription;

  static StreamSubscription<String>?
      _tokenRefreshSubscription;


  static bool _initialized = false;
  static bool _processingQueue = false;
  static bool _checkingSession = false;

  static String? _activeScope;

  static final _NotificationLifecycleObserver
      _lifecycleObserver =
      _NotificationLifecycleObserver(
    onResume: () {
      unawaited(
        refreshSessionListener(),
      );
    },
  );

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _requestPermission();
    await _initLocalNotification();

    /*
     * Tidak memasang FirebaseMessaging.onMessage.
     * Aplikasi ini memakai Realtime Database + notifikasi lokal.
     * Menyalakan listener FCM sekaligus dapat membuat notifikasi
     * yang sama tampil dua kali.
     */

    WidgetsBinding.instance.addObserver(
      _lifecycleObserver,
    );

    await refreshSessionListener();

    /*
     * Mendeteksi login/logout tanpa perlu mengubah alur halaman.
     * Timer hanya memeriksa perubahan role/NIK dan tidak menulis
     * data apa pun ke Firebase.
     */
    Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        unawaited(
          refreshSessionListener(),
        );
      },
    );
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _initLocalNotification() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> refreshSessionListener() async {
    if (!_initialized || _checkingSession) {
      return;
    }

    _checkingSession = true;

    try {
      final role = (await SessionHelper.getRole())
          ?.trim()
          .toLowerCase();

      String? nextScope;

      if (role == 'admin') {
        nextScope = 'admin';
      } else if (role == 'user') {
        final nik = (await SessionHelper.getNik())
            ?.trim();

        if (nik != null && nik.isNotEmpty) {
          nextScope = 'user:$nik';
        }
      }

      if (nextScope == _activeScope) {
        return;
      }

      await _switchScope(nextScope);
    } finally {
      _checkingSession = false;
    }
  }

  static Future<void> _switchScope(
    String? nextScope,
  ) async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _activeScope = nextScope;
    _knownFirebaseIds.clear();

    _queue.clear();
    _queuedIds.clear();

    if (nextScope == null) {
      return;
    }

    await _loadShownIds(nextScope);

    final reference = _referenceForScope(
      nextScope,
    );

    await _loadInitialNotifications(
      scope: nextScope,
      reference: reference,
    );

    _notificationSubscription =
        reference.onChildAdded.listen(
      (event) {
        final key = event.snapshot.key;

        if (key == null || key.trim().isEmpty) {
          return;
        }

        final uniqueId = '$nextScope/$key';

        /*
         * onChildAdded juga mengirim data lama ketika listener
         * pertama kali dipasang. Data awal sudah diproses oleh
         * _loadInitialNotifications, jadi dilewati di sini.
         */
        if (_knownFirebaseIds.contains(uniqueId)) {
          return;
        }

        _knownFirebaseIds.add(uniqueId);

        final item = _parseSnapshot(
          scope: nextScope,
          snapshot: event.snapshot,
        );

        if (item == null) {
          return;
        }

        unawaited(
          _enqueue(item),
        );
      },
    );
  }

  static DatabaseReference _referenceForScope(
    String scope,
  ) {
    if (scope == 'admin') {
      return _db.ref('notifikasi_admin');
    }

    final nik = scope.substring(
      'user:'.length,
    );

    return _db.ref('notifikasi').child(nik);
  }

  static Future<void> _loadInitialNotifications({
    required String scope,
    required DatabaseReference reference,
  }) async {
    final snapshot = await reference.get().timeout(
      const Duration(seconds: 12),
    );

    if (!snapshot.exists ||
        snapshot.value == null ||
        snapshot.value is! Map) {
      return;
    }

    final data = Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final items = <_QueuedNotification>[];

    for (final entry in data.entries) {
      final key = entry.key.toString();

      if (entry.value is! Map) {
        continue;
      }

      final uniqueId = '$scope/$key';

      _knownFirebaseIds.add(uniqueId);

      final item = _parseMap(
        scope: scope,
        key: key,
        value: Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      if (item != null) {
        items.add(item);
      }
    }

    /*
     * Paling lama ditampilkan lebih dahulu.
     * Jika ada dua atau lebih notifikasi saat user belum masuk,
     * notifikasi muncul satu per satu sesuai urutan tanggal.
     */
    items.sort(
      (a, b) => a.createdAt.compareTo(
        b.createdAt,
      ),
    );

    for (final item in items) {
      await _enqueue(item);
    }
  }

  static _QueuedNotification? _parseSnapshot({
    required String scope,
    required DataSnapshot snapshot,
  }) {
    final key = snapshot.key;
    final value = snapshot.value;

    if (key == null || value is! Map) {
      return null;
    }

    return _parseMap(
      scope: scope,
      key: key,
      value: Map<dynamic, dynamic>.from(value),
    );
  }

  static _QueuedNotification? _parseMap({
    required String scope,
    required String key,
    required Map<dynamic, dynamic> value,
  }) {
    if (!_isUnread(value)) {
      return null;
    }

    final title = _text(
      value['judul'] ?? value['title'],
      fallback: 'Notifikasi TaniGo',
    );

    final body = _text(
      value['pesan'] ?? value['body'],
      fallback: 'Ada informasi baru.',
    );

    final uniqueId = '$scope/$key';

    return _QueuedNotification(
      uniqueId: uniqueId,
      scope: scope,
      title: title,
      body: body,
      createdAt: _readDate(value),
    );
  }

  static bool _isUnread(
    Map<dynamic, dynamic> value,
  ) {
    final dibaca = value['dibaca'];

    if (dibaca == true) {
      return false;
    }

    final status = (value['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    return status != 'dibaca' &&
        status != 'sudah_dibaca';
  }

  static String _text(
    dynamic value, {
    required String fallback,
  }) {
    final text = (value ?? '')
        .toString()
        .trim();

    return text.isEmpty ? fallback : text;
  }

  static DateTime _readDate(
    Map<dynamic, dynamic> value,
  ) {
    final raw =
        value['timestamp'] ??
        value['tanggal'] ??
        value['created_at'] ??
        value['createdAt'];

    if (raw is int) {
      if (raw.toString().length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(
          raw,
        );
      }

      return DateTime.fromMillisecondsSinceEpoch(
        raw * 1000,
      );
    }

    if (raw is double) {
      final number = raw.toInt();

      if (number.toString().length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(
          number,
        );
      }

      return DateTime.fromMillisecondsSinceEpoch(
        number * 1000,
      );
    }

    final parsed = DateTime.tryParse(
      (raw ?? '').toString(),
    );

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Future<void> _enqueue(
    _QueuedNotification item,
  ) async {
    final shown = await _shownIds(
      item.scope,
    );

    if (shown.contains(item.uniqueId) ||
        _queuedIds.contains(item.uniqueId)) {
      return;
    }

    _queue.add(item);
    _queuedIds.add(item.uniqueId);

    _queue.sort(
      (a, b) => a.createdAt.compareTo(
        b.createdAt,
      ),
    );

    unawaited(
      _processQueue(),
    );
  }

  static Future<void> _processQueue() async {
    if (_processingQueue) {
      return;
    }

    _processingQueue = true;

    try {
      while (_queue.isNotEmpty) {
        final item = _queue.removeAt(0);
        _queuedIds.remove(item.uniqueId);

        final shown = await _shownIds(
          item.scope,
        );

        if (shown.contains(item.uniqueId)) {
          continue;
        }

        await _showQueuedNotification(item);
        await _markShown(item);

        /*
         * Jeda membuat beberapa notifikasi tampil satu per satu,
         * bukan meledak bersamaan di notification tray.
         */
        if (_queue.isNotEmpty) {
          await Future<void>.delayed(
            const Duration(seconds: 2),
          );
        }
      }
    } finally {
      _processingQueue = false;
    }
  }

  static Future<void> _showQueuedNotification(
    _QueuedNotification item,
  ) async {
    const androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation:
          BigTextStyleInformation(''),
      category: AndroidNotificationCategory.message,
      autoCancel: true,
      onlyAlertOnce: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      _stableNotificationId(
        item.uniqueId,
      ),
      item.title,
      item.body,
      details,
      payload: item.uniqueId,
    );
  }

  static int _stableNotificationId(
    String value,
  ) {
    int hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    return hash;
  }

  static Future<Set<String>> _shownIds(
    String scope,
  ) async {
    if (_shownByScope.containsKey(scope)) {
      return _shownByScope[scope]!;
    }

    await _loadShownIds(scope);

    return _shownByScope[scope]!;
  }

  static Future<void> _loadShownIds(
    String scope,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final values = prefs.getStringList(
      '$_shownPrefix$scope',
    );

    _shownByScope[scope] = {
      ...?values,
    };
  }

  static Future<void> _markShown(
    _QueuedNotification item,
  ) async {
    final shown = await _shownIds(
      item.scope,
    );

    shown.add(item.uniqueId);

    /*
     * Batasi riwayat lokal supaya SharedPreferences tidak tumbuh
     * tanpa batas. ID paling baru tetap dipertahankan.
     */
    final values = shown.toList();

    final trimmed = values.length > _maxShownIds
        ? values.sublist(
            values.length - _maxShownIds,
          )
        : values;

    _shownByScope[item.scope] = {
      ...trimmed,
    };

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      '$_shownPrefix${item.scope}',
      trimmed,
    );
  }

  /*
   * Tetap kompatibel dengan pemanggilan lama dari Dashboard.
   * Untuk hasil anti-duplikat terbaik, kirim notificationKey
   * berupa key Firebase.
   */
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? notificationKey,
    DateTime? createdAt,
    String scope = 'manual',
  }) async {
    final cleanKey =
        (notificationKey ?? '').trim();

    final fallbackKey = _stableNotificationId(
      '$scope|$title|$body',
    ).toString();

    final item = _QueuedNotification(
      uniqueId:
          '$scope/${cleanKey.isEmpty ? fallbackKey : cleanKey}',
      scope: scope,
      title: title,
      body: body,
      createdAt: createdAt ?? DateTime.now(),
    );

    await _enqueue(item);
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }

  static Future<void> saveTokenForUser(
    String nik,
  ) async {
    final cleanNik = nik.trim();

    if (cleanNik.isEmpty) {
      return;
    }

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    await _db.ref('anggota').child(cleanNik).update({
      'fcm_token': token,
      'updated_token_at':
          DateTime.now().toIso8601String(),
    });

    await _db
        .ref('fcm_tokens')
        .child(cleanNik)
        .child(token)
        .set({
      'nik': cleanNik,
      'token': token,
      'platform': 'android',
      'updated_at':
          DateTime.now().toIso8601String(),
    });

    await _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(
      (newToken) async {
        if (newToken.isEmpty) {
          return;
        }

        await _db
            .ref('anggota')
            .child(cleanNik)
            .update({
          'fcm_token': newToken,
          'updated_token_at':
              DateTime.now().toIso8601String(),
        });

        await _db
            .ref('fcm_tokens')
            .child(cleanNik)
            .child(newToken)
            .set({
          'nik': cleanNik,
          'token': newToken,
          'platform': 'android',
          'updated_at':
              DateTime.now().toIso8601String(),
        });
      },
    );
  }

  static Future<void> clearLocalShownHistory({
    String? scope,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (scope != null && scope.trim().isNotEmpty) {
      final cleanScope = scope.trim();

      _shownByScope.remove(cleanScope);

      await prefs.remove(
        '$_shownPrefix$cleanScope',
      );

      return;
    }

    final keys = prefs.getKeys().where(
      (key) => key.startsWith(_shownPrefix),
    );

    for (final key in keys) {
      await prefs.remove(key);
    }

    _shownByScope.clear();
  }
}

class _QueuedNotification {
  final String uniqueId;
  final String scope;
  final String title;
  final String body;
  final DateTime createdAt;

  const _QueuedNotification({
    required this.uniqueId,
    required this.scope,
    required this.title,
    required this.body,
    required this.createdAt,
  });
}

class _NotificationLifecycleObserver
    extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _NotificationLifecycleObserver({
    required this.onResume,
  });

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}