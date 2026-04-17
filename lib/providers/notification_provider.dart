// providers/notification_provider.dart

import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api;

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  NotificationProvider(this._api);

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> fetchNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _api.getNotifications();
      // Sort newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String notificationId) async {
    // Optimistic update
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      await _api.markNotificationRead(notificationId);
    } catch (_) {
      // Roll back on failure
      _notifications[idx] = _notifications[idx].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;

    // Optimistic update
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _api.markAllNotificationsRead();
    } catch (_) {
      // Re-fetch to restore correct state on failure
      await fetchNotifications();
    }
  }

  /// Called by PushNotificationService when a new notification arrives
  /// while the app is in the foreground — prepends it without a network call.
  void addLocalNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
