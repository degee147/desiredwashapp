// services/push_notification_service.dart
//
// Dependencies to add to pubspec.yaml:
//   firebase_core: ^3.x.x
//   firebase_messaging: ^15.x.x
//   flutter_local_notifications: ^17.x.x
//
// Android: Add google-services.json to android/app/
// iOS: Add GoogleService-Info.plist to ios/Runner/
//      Enable Push Notifications & Background Modes capabilities in Xcode.
//
// In main.dart, call PushNotificationService().init(context) after
// WidgetsFlutterBinding.ensureInitialized() and Firebase.initializeApp().

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

// ─── Top-level background handler (required by FCM) ──────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised when this is called.
  debugPrint('📬 FCM background message: ${message.messageId}');
  // We don't update provider state here (isolate has no Provider tree).
  // The notification is shown by FCM/system automatically.
}

// ─── Service ─────────────────────────────────────────────────────────────────

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'desiredwash_orders';
  static const _channelName = 'Order Updates';
  static const _channelDesc = 'Pickup, delivery, and payment notifications';

  /// Callback invoked when user taps a notification (foreground or background).
  /// Passes the [orderId] payload if present so the app can deep-link.
  void Function(String? orderId)? onNotificationTap;

  /// Callback invoked when a foreground message arrives — lets callers
  /// update the [NotificationProvider] without a circular dependency.
  void Function(AppNotification)? onForegroundMessage;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Set up Android notification channel
    await _setupLocalNotifications();

    // 4. Foreground presentation options (iOS shows banner+sound+badge)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Token — register with backend
    await _registerToken();

    // 6. Token refresh listener
    _fcm.onTokenRefresh.listen((token) async {
      await _safeRegisterToken(token);
    });

    // 7. Foreground messages → show local notification + update provider
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 8. App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 9. App launched from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _safeRegisterToken(token);
    } catch (e) {
      debugPrint('⚠️  FCM token fetch failed: $e');
    }
  }

  /// Re-registers the FCM token with the backend.
  /// Call this after any successful login/signup so the request
  /// goes out with a valid Authorization header.
  Future<void> registerTokenIfReady() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _safeRegisterToken(token);
    } catch (e) {
      debugPrint('⚠️  registerTokenIfReady failed: $e');
    }
  }

  Future<void> _safeRegisterToken(String token) async {
    debugPrint('📱 FCM token: $token');
    try {
      await ApiService().registerFcmToken(token);
    } catch (e) {
      debugPrint('⚠️  Failed to register FCM token with backend: $e');
    }
  }

  // ── Local notifications setup ──────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        final orderId = payload != null ? _extractOrderId(payload) : null;
        onNotificationTap?.call(orderId);
      },
    );

    // Create Android channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 FCM foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Show local notification (FCM doesn't auto-show on Android foreground)
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'DesiredWash',
        body: notification.body ?? '',
        payload: jsonEncode(data),
      );
    }

    // Notify provider to insert notification into the list
    final appNotif = _remoteMessageToAppNotification(message);
    if (appNotif != null) onForegroundMessage?.call(appNotif);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final orderId = message.data['order_id']?.toString();
    onNotificationTap?.call(orderId);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AppNotification? _remoteMessageToAppNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return null;
    final data = message.data;

    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: n.title ?? 'DesiredWash',
      body: n.body ?? '',
      type:
          AppNotification.typeFromString(data['type'] as String? ?? 'general'),
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
      orderId: data['order_id']?.toString(),
    );
  }

  String? _extractOrderId(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['order_id']?.toString();
    } catch (_) {
      return null;
    }
  }
}
