import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import 'order_detail_screen.dart';
import '../pickup/schedule_pickup_screen.dart';






class OrdersScreen extends StatefulWidget {
  final bool embedded;
  const OrdersScreen({super.key, this.embedded = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<PickupOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _orders = await context.read<ApiService>().getOrders();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<PickupOrder> get _active => _orders
      .where((o) => ![OrderStatus.delivered, OrderStatus.cancelled].contains(o.status))
      .toList();

  List<PickupOrder> get _past => _orders
      .where((o) => [OrderStatus.delivered, OrderStatus.cancelled].contains(o.status))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Orders', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkText), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.coral,
          labelColor: AppColors.coral,
          unselectedLabelColor: AppColors.warmGray,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _OrderList(orders: _active, emptyMessage: 'No active orders', emptyIcon: Icons.local_laundry_service_outlined),
                      _OrderList(orders: _past, emptyMessage: 'No past orders yet', emptyIcon: Icons.history_rounded),
                    ],
                  ),
                ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<PickupOrder> orders;
  final String emptyMessage;
  final IconData emptyIcon;

  const _OrderList({required this.orders, required this.emptyMessage, required this.emptyIcon});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(emptyMessage, style: const TextStyle(color: AppColors.warmGray, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SchedulePickupScreen())),
              child: const Text('Schedule a pickup →', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(order: orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PickupOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final status = _statusMeta(order.status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.darkText),
                ),
                const Spacer(),
                _StatusBadge(label: status.label, color: status.color),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(Icons.location_on_outlined, order.zoneName),
            const SizedBox(height: 4),
            _InfoRow(
              Icons.calendar_today_outlined,
              '${DateFormat('EEE, MMM d').format(order.scheduledPickupDate)} · ${order.scheduledPickupTime}',
            ),
            const SizedBox(height: 4),
            _InfoRow(Icons.inventory_2_outlined, '${order.items.length} service(s)'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₦${fmt.format(order.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkText)),
                Row(
                  children: [
                    Icon(_paymentIcon(order.paymentMethod), size: 14, color: AppColors.warmGray),
                    const SizedBox(width: 4),
                    Text(_paymentLabel(order.paymentMethod),
                        style: const TextStyle(fontSize: 12, color: AppColors.warmGray)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.warmGray, size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusMeta _statusMeta(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return _StatusMeta('Pending', const Color(0xFFF39C12));
      case OrderStatus.confirmed: return _StatusMeta('Confirmed', const Color(0xFF3498DB));
      case OrderStatus.pickedUp: return _StatusMeta('Picked Up', const Color(0xFF9B59B6));
      case OrderStatus.washing: return _StatusMeta('Washing', const Color(0xFF1ABC9C));
      case OrderStatus.readyForDelivery: return _StatusMeta('Ready', const Color(0xFF27AE60));
      case OrderStatus.delivered: return _StatusMeta('Delivered', const Color(0xFF2ECC71));
      case OrderStatus.cancelled: return _StatusMeta('Cancelled', Colors.grey);
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card: return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer: return Icons.account_balance_rounded;
      case PaymentMethod.wallet: return Icons.account_balance_wallet_rounded;
    }
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank';
      case PaymentMethod.wallet: return 'Wallet';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.warmGray),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.warmGray))),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(error, style: const TextStyle(color: AppColors.warmGray), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(color: AppColors.coral))),
      ],
    ),
  );
}

class _StatusMeta {
  final String label;
  final Color color;
  _StatusMeta(this.label, this.color);
}
