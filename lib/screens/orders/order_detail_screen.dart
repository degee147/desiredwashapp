import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  PickupOrder? _order;
  bool _loading = true;
  bool _cancelling = false;
  String? _error;

  final fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await context.read<ApiService>().getOrder(widget.orderId);
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this pickup?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _cancelling = true);
    try {
      await context.read<ApiService>().cancelOrder(widget.orderId);

      // Refresh order state in provider so Orders list updates
      context.read<OrderProvider>().refreshOrder(widget.orderId);

      // Pull fresh notifications so the cancellation notice appears immediately
      context.read<NotificationProvider>().fetchNotifications();

      await _load();

      if (mounted) {
        final wasWallet = _order?.paymentMethod == PaymentMethod.wallet &&
            _order?.paymentStatus == PaymentStatus.success;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: wasWallet
                    ? const Color(0xFF2E7D60)
                    : const Color(0xFF333333),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    wasWallet
                        ? Icons.account_balance_wallet_rounded
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wasWallet
                          ? 'Order cancelled. ₦${fmt.format(_order!.total)} refunded to wallet.'
                          : 'Order cancelled successfully.',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.darkText),
                onPressed: () => Navigator.pop(context))),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error ?? 'Order not found',
                style: const TextStyle(color: AppColors.warmGray)),
            const SizedBox(height: 16),
            TextButton(
                onPressed: _load,
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.coral))),
          ],
        )),
      );
    }

    final order = _order!;
    final canCancel =
        [OrderStatus.pending, OrderStatus.confirmed].contains(order.status);

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
        title: Text('#${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
              icon:
                  const Icon(Icons.refresh_rounded, color: AppColors.darkText),
              onPressed: _load),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status timeline
            _Section(
              title: 'Order Status',
              child: _StatusTimeline(status: order.status),
            ),
            const SizedBox(height: 16),

            // Pickup info
            _Section(
              title: 'Pickup Details',
              child: Column(
                children: [
                  _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Zone',
                      value: order.zoneName),
                  _DetailRow(
                      icon: Icons.home_rounded,
                      label: 'Address',
                      value: order.address),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('EEEE, MMMM d, y')
                        .format(order.scheduledPickupDate),
                  ),
                  _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time Slot',
                      value: order.scheduledPickupTime),
                  if (order.notes != null)
                    _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'Notes',
                        value: order.notes!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Services
            _Section(
              title: 'Services (${order.items.length})',
              child: Column(
                children: [
                  ...order.items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              if (item.emoji != null) ...[
                                Text(item.emoji!,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.serviceName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.darkText)),
                                    Text(
                                        '${item.quantity} × ₦${fmt.format(item.unitPrice)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.warmGray)),
                                  ],
                                ),
                              ),
                              Text('₦${fmt.format(item.total)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.darkText)),
                            ],
                          ),
                        ),
                        if (i < order.items.length - 1)
                          Divider(height: 1, color: Colors.grey.shade100),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment summary
            _Section(
              title: 'Payment',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.receipt_outlined,
                    label: 'Method',
                    value: _paymentMethodLabel(order.paymentMethod),
                  ),
                  _DetailRow(
                    icon: Icons.check_circle_outline,
                    label: 'Status',
                    value: order.paymentStatus.name.toUpperCase(),
                    valueColor: order.paymentStatus == PaymentStatus.success
                        ? const Color(0xFF2ECC71)
                        : order.paymentStatus == PaymentStatus.failed
                            ? Colors.red
                            : const Color(0xFFF39C12),
                  ),
                  if (order.flutterwaveRef != null)
                    _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Ref',
                        value: order.flutterwaveRef!),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(
                              color: AppColors.warmGray, fontSize: 13)),
                      Text('₦${fmt.format(order.subtotal)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee',
                          style: TextStyle(
                              color: AppColors.warmGray, fontSize: 13)),
                      Text('₦${fmt.format(order.deliveryFee)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.darkText)),
                      Text('₦${fmt.format(order.total)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.darkText)),
                    ],
                  ),
                ],
              ),
            ),

            if (canCancel) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _cancelling
                      ? const CircularProgressIndicator(
                          color: Colors.red, strokeWidth: 2)
                      : const Text('Cancel Order',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _paymentMethodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'Card (Flutterwave)';
      case PaymentMethod.wallet:
        return 'Wallet Balance';
    }
  }
}

// ─── STATUS TIMELINE ─────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final OrderStatus status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    _Step(OrderStatus.pending, 'Order Placed', Icons.receipt_long_rounded),
    _Step(
        OrderStatus.confirmed, 'Confirmed', Icons.check_circle_outline_rounded),
    _Step(OrderStatus.pickedUp, 'Picked Up', Icons.local_shipping_rounded),
    _Step(OrderStatus.washing, 'Washing', Icons.local_laundry_service_rounded),
    _Step(OrderStatus.readyForDelivery, 'Ready', Icons.inventory_rounded),
    _Step(OrderStatus.delivered, 'Delivered', Icons.home_rounded),
  ];

  int get _currentIndex {
    if (status == OrderStatus.cancelled) return -1;
    return _steps.indexWhere((s) => s.status == status);
  }

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.red.shade50, shape: BoxShape.circle),
            child:
                const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Order Cancelled',
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ],
      );
    }

    return Column(
      children: _steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isDone = i <= _currentIndex;
        final isActive = i == _currentIndex;
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.coral : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: AppColors.coral.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: Icon(step.icon,
                      size: 18,
                      color: isDone ? Colors.white : Colors.grey.shade400),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 2,
                    height: 28,
                    color: i < _currentIndex
                        ? AppColors.coral
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: EdgeInsets.only(top: 7, bottom: isLast ? 0 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      fontSize: isActive ? 15 : 13,
                      color: isDone ? AppColors.darkText : Colors.grey.shade400,
                    ),
                  ),
                  if (isActive)
                    Text('In progress',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.coral.withOpacity(0.8))),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _Step {
  final OrderStatus status;
  final String label;
  final IconData icon;
  const _Step(this.status, this.label, this.icon);
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: child,
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.warmGray),
            const SizedBox(width: 10),
            SizedBox(
                width: 72,
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.warmGray, fontSize: 13))),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: valueColor ?? AppColors.darkText),
              ),
            ),
          ],
        ),
      );
}
