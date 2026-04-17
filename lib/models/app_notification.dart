// models/app_notification.dart

enum NotificationType {
  orderConfirmed,
  orderPickedUp,
  orderReady,
  orderDelivered,
  orderCancelled,
  paymentSuccess,
  paymentFailed,
  walletTopup,
  promo,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? orderId; // deep-link payload

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        orderId: orderId,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: json['title'] as String,
        body: json['body'] as String,
        type: typeFromString(json['type'] as String? ?? 'general'),
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        orderId: json['order_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
        if (orderId != null) 'order_id': orderId,
      };

  /// Public so PushNotificationService can call it from outside the class.
  static NotificationType typeFromString(String s) {
    switch (s) {
      case 'order_confirmed':
        return NotificationType.orderConfirmed;
      case 'order_picked_up':
        return NotificationType.orderPickedUp;
      case 'order_ready':
        return NotificationType.orderReady;
      case 'order_delivered':
        return NotificationType.orderDelivered;
      case 'order_cancelled':
        return NotificationType.orderCancelled;
      case 'payment_success':
        return NotificationType.paymentSuccess;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'wallet_topup':
        return NotificationType.walletTopup;
      case 'promo':
        return NotificationType.promo;
      default:
        return NotificationType.general;
    }
  }
}
