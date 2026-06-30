import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this is called
  debugPrint('Background push received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'chiraag_default_channel',
      'Chiraag e Azaa Notifications',
      description: 'Updates, reminders and announcements',
      importance: Importance.high,
    );

    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _localNotifs.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // Foreground notification display options
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifs.show(
        notification.hashCode,
        notification.title ?? 'Chiraag e Azaa',
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  /// Request permission from the user. Returns true if granted.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final settings = await _fm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      }
      // Android 13+ permission is requested automatically on first subscribe
      return true;
    } catch (error, stackTrace) {
      debugPrint('Push permission unavailable: $error\n$stackTrace');
      return false;
    }
  }

  /// Get the current FCM token (send this to your backend)
  Future<String?> getToken() async {
    try {
      return await _fm.getToken();
    } catch (error, stackTrace) {
      debugPrint('Push token unavailable: $error\n$stackTrace');
      return null;
    }
  }

  /// Subscribe to a topic (e.g. "general")
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fm.subscribeToTopic(topic);
    } catch (error, stackTrace) {
      debugPrint('Push topic subscribe unavailable: $error\n$stackTrace');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fm.unsubscribeFromTopic(topic);
    } catch (error, stackTrace) {
      debugPrint('Push topic unsubscribe unavailable: $error\n$stackTrace');
    }
  }

  /// Check current notification permission status
  Future<AuthorizationStatus> getStatus() async {
    try {
      final settings = await _fm.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (error, stackTrace) {
      debugPrint('Push status unavailable: $error\n$stackTrace');
      return AuthorizationStatus.notDetermined;
    }
  }
}
