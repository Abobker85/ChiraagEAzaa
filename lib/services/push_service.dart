import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme.dart';
import 'settings_service.dart';

/// Background message handler for FCM — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background push received: ${message.messageId}');
}

class LocalizedNotificationContent {
  final String title;
  final String body;
  final String channelName;
  final String channelDesc;
  final String testTitle;
  final String testBody;

  const LocalizedNotificationContent({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDesc,
    required this.testTitle,
    required this.testBody,
  });
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _localNotifs = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseReady = false;

  static const _dailyNotifId = 1001;
  static const _testNotifId = 1002;

  static const String _defaultChannelId = 'chiraag_default_channel';
  static const String _dailyChannelId = 'chiraag_daily_channel';

  /// Get device language code (e.g. 'ar', 'ur', 'en')
  static String getDeviceLanguageCode() {
    try {
      return ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    } catch (_) {
      return 'en';
    }
  }

  /// Human-readable name of detected device language
  static String getDeviceLanguageDisplay() {
    final code = getDeviceLanguageCode();
    if (code.startsWith('ar')) return 'العربية 🇸🇦';
    if (code.startsWith('ur')) return 'اردو 🇵🇰';
    return 'English 🌐';
  }

  /// Get localized notification strings according to device language
  static LocalizedNotificationContent getLocalizedContent([String? langCode]) {
    final code = (langCode ?? getDeviceLanguageCode()).toLowerCase();
    if (code.startsWith('ar')) {
      return const LocalizedNotificationContent(
        title: 'چراغ عزا • تذكير الأدعية والزيارات',
        body: 'السلام عليك يا أبا عبد الله الحسين • حان وقت قراءة أدعية اليوم والزيارة 🤲',
        channelName: 'أذكار وأدعية چراغ عزا',
        channelDesc: 'تنبيهات يومية لقراءة الأدعية والزيارات والتسبيح',
        testTitle: 'چراغ عزا • إشعار تجريبي 🔔',
        testBody: 'تم تفعيل التنبيهات الداخلية بنجاح باللغة العربية. نسألكم الدعاء.',
      );
    } else if (code.startsWith('ur')) {
      return const LocalizedNotificationContent(
        title: 'چراغِ عزا • روزانہ دعا و زیارت',
        body: 'السلام علیک یا ابا عبد اللہ الحسین • روزانہ کی دعائیں اور زیارات پڑھنے کا وقت ہے 🤲',
        channelName: 'چراغِ عزا روزانہ دعائیں و زیارات',
        channelDesc: 'روزانہ تسبیح، نوحہ اور زیارات کی یاد دہانی',
        testTitle: 'چراغِ عزا • آزمائشی اطلاع 🔔',
        testBody: 'اردو زبان میں اندرونی اطلاعات کامیابی سے فعال کر دی گئی ہیں۔ التماسِ دعا۔',
      );
    } else {
      return const LocalizedNotificationContent(
        title: 'Chiraag e Azaa • Daily Dua & Ziyarat',
        body: 'Peace be upon you, O Aba Abdillah • Take a moment for today\'s Dua & Ziyarat 🤲',
        channelName: 'Daily Recitations & Reminders',
        channelDesc: 'Daily reminders for Duas, Ziyaraat and Tasbih',
        testTitle: 'Chiraag e Azaa • Test Notification 🔔',
        testBody: 'System notifications activated successfully in English. Remember us in your prayers.',
      );
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      // 1. Initialize local system notification plugin
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifs.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      // 2. Create localized Android channels
      final content = getLocalizedContent();
      final androidImpl = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      const defaultChannel = AndroidNotificationChannel(
        _defaultChannelId,
        'Chiraag e Azaa Notifications',
        description: 'Updates and announcements',
        importance: Importance.high,
      );

      final dailyChannel = AndroidNotificationChannel(
        _dailyChannelId,
        content.channelName,
        description: content.channelDesc,
        importance: Importance.high,
      );

      await androidImpl?.createNotificationChannel(defaultChannel);
      await androidImpl?.createNotificationChannel(dailyChannel);

      // 3. Schedule daily reminders if enabled in settings
      if (AppSettings.instance.dailyRemindersEnabled) {
        await scheduleDailyReminders();
      }

      // 4. Safely initialize Firebase Cloud Messaging if available
      _initFirebase();
    } catch (e, st) {
      debugPrint('Local notifications init error: $e\n$st');
    }
  }

  void _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification == null) return;
        _localNotifs.show(
          notification.hashCode,
          notification.title ?? 'Chiraag e Azaa',
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _defaultChannelId,
              'Chiraag e Azaa Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: AppTheme.green,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      });
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase messaging optional init skipped: $e');
    }
  }

  /// Request notification permission on Android 13+ and iOS. Returns true if granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isIOS) {
        if (_firebaseReady) {
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          return settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        }
        final iosImpl = _localNotifs.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (Platform.isAndroid) {
        final androidImpl = _localNotifs.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('Notification permission error: $error\n$stackTrace');
      return false;
    }
  }

  /// Show an immediate test notification in the device's selected language
  Future<bool> showTestNotification() async {
    if (kIsWeb) return false;
    try {
      final granted = await requestPermission();
      if (!granted) return false;

      final content = getLocalizedContent();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          content.channelName,
          channelDescription: content.channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: AppTheme.green,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifs.show(
        _testNotifId,
        content.testTitle,
        content.testBody,
        details,
      );
      return true;
    } catch (e, st) {
      debugPrint('Failed to show test notification: $e\n$st');
      return false;
    }
  }

  /// Schedule daily recurring reminder in the device's selected language
  Future<void> scheduleDailyReminders() async {
    if (kIsWeb) return;
    try {
      final content = getLocalizedContent();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          content.channelName,
          channelDescription: content.channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: AppTheme.green,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifs.cancel(_dailyNotifId);
      await _localNotifs.periodicallyShow(
        _dailyNotifId,
        content.title,
        content.body,
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Daily reminder scheduled successfully in ${getDeviceLanguageCode()}');
    } catch (e, st) {
      debugPrint('Failed to schedule daily reminders: $e\n$st');
    }
  }

  /// Cancel daily reminders
  Future<void> cancelDailyReminders() async {
    if (kIsWeb) return;
    try {
      await _localNotifs.cancel(_dailyNotifId);
      debugPrint('Daily reminders cancelled');
    } catch (e) {
      debugPrint('Cancel daily reminders error: $e');
    }
  }

  /// Get current FCM token if available
  Future<String?> getToken() async {
    if (!_firebaseReady) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      return null;
    }
  }

  /// Subscribe to FCM topic (e.g. "general")
  Future<void> subscribeToTopic(String topic) async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  /// Check current notification permission status
  Future<AuthorizationStatus> getStatus() async {
    if (kIsWeb) return AuthorizationStatus.notDetermined;
    try {
      if (_firebaseReady) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        return settings.authorizationStatus;
      }
      return AuthorizationStatus.authorized;
    } catch (_) {
      return AuthorizationStatus.authorized;
    }
  }
}
