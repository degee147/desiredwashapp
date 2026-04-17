// screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: provider.markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.loading && provider.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Could not load notifications',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: provider.fetchNotifications,
                child: const Text('Try again',
                    style: TextStyle(color: AppColors.coral)),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 44, color: AppColors.coral),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll let you know when your\norder status changes.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.warmGray),
            ),
          ],
        ),
      );
    }

    // Group by date: Today / Yesterday / earlier
    final grouped = _groupByDate(provider.notifications);

    return RefreshIndicator(
      color: AppColors.coral,
      onRefresh: provider.fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final entry = grouped[i];
          if (entry is _DateHeader) {
            return _buildDateHeader(entry.label);
          }
          final notif = entry as AppNotification;
          return _NotificationTile(
            notification: notif,
            onTap: () =>
                context.read<NotificationProvider>().markRead(notif.id),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.warmGray,
              letterSpacing: 0.5),
        ),
      );

  List<dynamic> _groupByDate(List<AppNotification> items) {
    final result = <dynamic>[];
    String? currentLabel;

    for (final n in items) {
      final label = _dateLabel(n.createdAt);
      if (label != currentLabel) {
        result.add(_DateHeader(label));
        currentLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(dt); // e.g. "Monday"
    return DateFormat('d MMM yyyy').format(dt);
  }
}

class _DateHeader {
  final String label;
  const _DateHeader(this.label);
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final config = _NotificationConfig.from(n.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : config.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? Colors.grey.shade100 : config.borderColor,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(n.isRead ? 0.03 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: config.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.w600 : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.warmGray, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(n.createdAt),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(dt);
  }
}

// ─── Notification visual config ───────────────────────────────────────────────

class _NotificationConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color bgColor;
  final Color borderColor;

  const _NotificationConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.bgColor,
    required this.borderColor,
  });

  factory _NotificationConfig.from(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmed:
        return _NotificationConfig(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF2E7D60),
          iconBg: const Color(0xFFD6F5EC),
          bgColor: const Color(0xFFF0FBF7),
          borderColor: const Color(0xFFB2DFD8),
        );
      case NotificationType.orderPickedUp:
        return _NotificationConfig(
          icon: Icons.local_shipping_rounded,
          iconColor: const Color(0xFF1565C0),
          iconBg: const Color(0xFFD6E4FF),
          bgColor: const Color(0xFFF0F5FF),
          borderColor: const Color(0xFFB3C8F5),
        );
      case NotificationType.orderReady:
        return _NotificationConfig(
          icon: Icons.local_laundry_service_rounded,
          iconColor: AppColors.coral,
          iconBg: const Color(0xFFFFECEC),
          bgColor: const Color(0xFFFFF5F5),
          borderColor: const Color(0xFFFFCDD2),
        );
      case NotificationType.orderDelivered:
        return _NotificationConfig(
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF2E7D60),
          iconBg: const Color(0xFFD6F5EC),
          bgColor: const Color(0xFFF0FBF7),
          borderColor: const Color(0xFFB2DFD8),
        );
      case NotificationType.orderCancelled:
        return _NotificationConfig(
          icon: Icons.cancel_rounded,
          iconColor: Colors.red.shade400,
          iconBg: Colors.red.shade50,
          bgColor: const Color(0xFFFFF5F5),
          borderColor: Colors.red.shade100,
        );
      case NotificationType.paymentSuccess:
      case NotificationType.walletTopup:
        return _NotificationConfig(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF2E7D60),
          iconBg: const Color(0xFFD6F5EC),
          bgColor: const Color(0xFFF0FBF7),
          borderColor: const Color(0xFFB2DFD8),
        );
      case NotificationType.paymentFailed:
        return _NotificationConfig(
          icon: Icons.payment_rounded,
          iconColor: Colors.red.shade400,
          iconBg: Colors.red.shade50,
          bgColor: const Color(0xFFFFF5F5),
          borderColor: Colors.red.shade100,
        );
      case NotificationType.promo:
        return _NotificationConfig(
          icon: Icons.local_offer_rounded,
          iconColor: const Color(0xFF7B5EA7),
          iconBg: const Color(0xFFEDE7F6),
          bgColor: const Color(0xFFF8F5FF),
          borderColor: const Color(0xFFD1C4E9),
        );
      case NotificationType.general:
      default:
        return _NotificationConfig(
          icon: Icons.notifications_rounded,
          iconColor: AppColors.coral,
          iconBg: AppColors.cream,
          bgColor: const Color(0xFFFFFBF8),
          borderColor: AppColors.cream,
        );
    }
  }
}
