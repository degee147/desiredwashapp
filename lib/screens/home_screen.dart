import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/notification_provider.dart';
import '../models/order.dart';
import 'pickup/schedule_pickup_screen.dart';
import 'orders/orders_screen.dart';
import 'orders/order_detail_screen.dart';
import 'track_screen.dart';
import 'notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh profile so wallet balance & zone stay current
      context.read<AuthProvider>().refreshProfile();
      final op = context.read<OrderProvider>();
      if (op.orders.isEmpty && !op.loading) op.load();
      // Sync notification badge count
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final orders = context.watch<OrderProvider>();
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning ☀️'
        : hour < 17
            ? 'Good afternoon 👋'
            : 'Good evening 🌙';

    final initials = user != null
        ? user.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'U';

    // Latest active (non-delivered/cancelled) order for the banner
    final activeOrder = orders.orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .cast<PickupOrder?>()
        .firstOrNull;

    return RefreshIndicator(
      color: AppColors.coral,
      onRefresh: orders.load,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              _buildHeader(context, greeting, user?.name ?? 'there', initials,
                  unreadCount),
              const SizedBox(height: 24),

              // ── Active order banner (shown when there is an active order) ───
              if (activeOrder != null) ...[
                _buildActiveBanner(context, activeOrder),
                const SizedBox(height: 20),
              ],

              // ── Single "Create Order" CTA button ────────────────────────────
              _buildCreateOrderButton(context),
              const SizedBox(height: 28),

              // ── Recent orders ───────────────────────────────────────────────
              _buildRecentOrders(context, orders),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String greeting, String name,
      String initials, int unreadCount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.warmGray,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(name.split(' ').first,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText)),
            ],
          ),
        ),
        // 🔔 Notification bell with unread badge
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.notifications_outlined,
                      color: AppColors.darkText, size: 22),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SchedulePickupScreen())),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B5EA7),
                      fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Active order banner ──────────────────────────────────────────────────────

  Widget _buildActiveBanner(BuildContext context, PickupOrder order) {
    final statusText = _statusSubtitle(order);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7D5C), Color(0xFFFFB085)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.coral.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Active Order',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 10),
                  Text('#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(statusText,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrackScreen())),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusSubtitle(PickupOrder o) {
    switch (o.status) {
      case OrderStatus.pending:
        return 'Awaiting confirmation';
      case OrderStatus.confirmed:
        return 'Pickup on ${o.scheduledPickupTime}';
      case OrderStatus.pickedUp:
        return 'Your laundry is on the way!';
      case OrderStatus.washing:
        return 'Washing in progress 🧺';
      case OrderStatus.readyForDelivery:
        return 'Ready for delivery!';
      default:
        return o.status.name;
    }
  }

  // ── Create Order button ──────────────────────────────────────────────────────

  Widget _buildCreateOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePickupScreen()),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Create Order',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Recent orders ────────────────────────────────────────────────────────────

  Widget _buildRecentOrders(BuildContext context, OrderProvider orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
              child: const Text('See all',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.coral,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (orders.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          )
        else if (orders.orders.isEmpty)
          _buildEmptyOrders(context)
        else
          ...orders.orders.take(3).map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: o.id))),
                  child: OrderTile(
                    id: '#${o.id.substring(0, 8).toUpperCase()}',
                    service: o.items.isNotEmpty
                        ? o.items.first.serviceName
                        : 'Laundry',
                    status: _statusLabel(o.status),
                    date: _fmtDate(o.scheduledPickupDate),
                    statusColor: _statusColor(o.status),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildEmptyOrders(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SchedulePickupScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.local_laundry_service_outlined,
                size: 36, color: AppColors.warmGray.withOpacity(0.5)),
            const SizedBox(height: 8),
            const Text('No orders yet',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmGray)),
            const SizedBox(height: 4),
            const Text('Tap to schedule your first pickup →',
                style: TextStyle(fontSize: 12, color: AppColors.coral)),
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.washing:
        return 'Washing';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.readyForDelivery:
        return 'Ready';
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return AppColors.mintGreen;
      case OrderStatus.cancelled:
        return AppColors.warmGray;
      default:
        return AppColors.coral;
    }
  }

  String _fmtDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month]} ${d.day}';
  }
}
