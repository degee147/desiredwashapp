import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
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
  bool _paying = false;
  String? _error;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;

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

      context.read<OrderProvider>().refreshOrder(widget.orderId);
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

  Future<void> _showPaySheet() async {
    final order = _order!;
    final user = context.read<AuthProvider>().user;
    final walletBalance = user?.walletBalance ?? 0;
    final walletOk = walletBalance >= order.total;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayBottomSheet(
        total: order.total,
        walletBalance: walletBalance,
        walletOk: walletOk,
        initialMethod: _selectedPaymentMethod,
        onPay: (method) async {
          Navigator.pop(context);
          setState(() => _selectedPaymentMethod = method);
          await _processPayment(method);
        },
      ),
    );
  }

  Future<void> _processPayment(PaymentMethod method) async {
    final order = _order!;
    setState(() => _paying = true);

    try {
      final result = await context.read<ApiService>().payOrder(
            orderId: order.id,
            method: method,
          );

      if (!mounted) return;

      if (method == PaymentMethod.wallet) {
        // Wallet: paid immediately — refresh balance + order
        context.read<AuthProvider>().refreshProfile();
        context.read<OrderProvider>().refreshOrder(order.id);
        setState(() {
          _order = result.order;
          _paying = false;
        });
        _showSuccessSnack(
            'Payment successful! ₦${fmt.format(order.total)} deducted from wallet.');
      } else {
        // Card: open Flutterwave WebView
        setState(() => _paying = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FlutterwavePaymentScreen(
              order: order,
              paymentLink: result.paymentLink!,
              onSuccess: () async {
                if (mounted)
                  context.read<OrderProvider>().refreshOrder(order.id);
                await _load();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D60),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
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
    final needsPayment = order.paymentStatus == PaymentStatus.pending &&
        order.status != OrderStatus.cancelled;

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
            // ── Payment pending banner ────────────────────────────────────────
            if (needsPayment) ...[
              _PaymentPendingBanner(
                total: order.total,
                fmt: fmt,
                onPay: _paying ? null : _showPaySheet,
                paying: _paying,
              ),
              const SizedBox(height: 16),
            ],

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

            // ── Action buttons ────────────────────────────────────────────────
            if (needsPayment || canCancel) ...[
              const SizedBox(height: 24),
              if (needsPayment)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _showPaySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _paying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text('Pay ₦${fmt.format(order.total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              if (needsPayment && canCancel) const SizedBox(height: 12),
              if (canCancel)
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

// ─── PAYMENT PENDING BANNER ───────────────────────────────────────────────────

class _PaymentPendingBanner extends StatelessWidget {
  final double total;
  final NumberFormat fmt;
  final VoidCallback? onPay;
  final bool paying;

  const _PaymentPendingBanner({
    required this.total,
    required this.fmt,
    required this.onPay,
    required this.paying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment_rounded,
                color: Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Pending',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFFE65100))),
                SizedBox(height: 2),
                Text('Complete payment to confirm your order.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(10),
              ),
              child: paying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Pay Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PAY BOTTOM SHEET ─────────────────────────────────────────────────────────

class _PayBottomSheet extends StatefulWidget {
  final double total;
  final double walletBalance;
  final bool walletOk;
  final PaymentMethod initialMethod;
  final void Function(PaymentMethod) onPay;

  const _PayBottomSheet({
    required this.total,
    required this.walletBalance,
    required this.walletOk,
    required this.initialMethod,
    required this.onPay,
  });

  @override
  State<_PayBottomSheet> createState() => _PayBottomSheetState();
}

class _PayBottomSheetState extends State<_PayBottomSheet> {
  late PaymentMethod _selected;
  final fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _selected = widget.walletOk ? PaymentMethod.wallet : PaymentMethod.card;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Choose Payment Method',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText)),
          const SizedBox(height: 6),
          Text('Total: ₦${fmt.format(widget.total)}',
              style: const TextStyle(fontSize: 13, color: AppColors.warmGray)),
          const SizedBox(height: 20),

          // Card option
          _MethodTile(
            icon: Icons.credit_card_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            title: 'Pay by Card',
            subtitle: 'Powered by Flutterwave',
            method: PaymentMethod.card,
            selected: _selected,
            enabled: true,
            onTap: () => setState(() => _selected = PaymentMethod.card),
          ),
          const SizedBox(height: 10),

          // Wallet option
          _MethodTile(
            icon: Icons.account_balance_wallet_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            title: 'Pay with Wallet',
            subtitle: widget.walletOk
                ? '₦${fmt.format(widget.walletBalance)} available'
                : '₦${fmt.format(widget.walletBalance)} — insufficient (need ₦${fmt.format(widget.total)})',
            subtitleColor: widget.walletOk ? null : Colors.red.shade400,
            method: PaymentMethod.wallet,
            selected: _selected,
            enabled: widget.walletOk,
            onTap: widget.walletOk
                ? () => setState(() => _selected = PaymentMethod.wallet)
                : null,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onPay(_selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _selected == PaymentMethod.wallet
                    ? 'Pay ₦${fmt.format(widget.total)} from Wallet'
                    : 'Continue to Card Payment',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final PaymentMethod method;
  final PaymentMethod selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == method;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.coral.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.coral : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: enabled ? iconBg : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon,
                  color: enabled ? iconColor : Colors.grey.shade400, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: enabled
                              ? AppColors.darkText
                              : Colors.grey.shade400)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor ??
                              (enabled
                                  ? AppColors.warmGray
                                  : Colors.grey.shade400))),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: selected,
              onChanged: enabled ? (_) => onTap?.call() : null,
              activeColor: AppColors.coral,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FLUTTERWAVE PAYMENT WEBVIEW ──────────────────────────────────────────────

class _FlutterwavePaymentScreen extends StatefulWidget {
  final PickupOrder order;
  final String paymentLink;
  final Future<void> Function()? onSuccess;

  const _FlutterwavePaymentScreen({
    required this.order,
    required this.paymentLink,
    this.onSuccess,
  });

  @override
  State<_FlutterwavePaymentScreen> createState() =>
      _FlutterwavePaymentScreenState();
}

class _FlutterwavePaymentScreenState extends State<_FlutterwavePaymentScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final url = req.url;
          debugPrint('🌐 WebView navigating to: $url');

          if (url.contains('status=successful') ||
              url.contains('status=completed')) {
            final uri = Uri.parse(url);
            final txRef = uri.queryParameters['tx_ref'] ??
                uri.queryParameters['transaction_id'] ??
                '';
            _onPaymentSuccess(txRef);
            return NavigationDecision.prevent;
          }

          if (url.contains('status=cancelled') ||
              url.contains('status=failed')) {
            _onPaymentCancelled();
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentLink));
  }

  Future<void> _onPaymentSuccess(String txRef) async {
    if (_verifying) return;
    setState(() => _verifying = true);

    try {
      await context.read<ApiService>().verifyPayment(
            transactionRef: txRef,
            orderId: widget.order.id,
          );

      await widget.onSuccess?.call();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _onPaymentCancelled() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment was cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.darkText),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                    'Payment is incomplete. You can pay later from your order details.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Paying'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text('Leave',
                        style: TextStyle(color: Colors.red.shade600)),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Text('Complete Payment',
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_verifying)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.coral),
                    SizedBox(height: 16),
                    Text('Verifying payment…',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
