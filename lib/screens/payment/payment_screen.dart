import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../orders/orders_screen.dart';

/// Handles both:
///   - Card/Bank: loads Flutterwave payment link in WebView
///   - Wallet: shows confirmation, deducts directly via backend
class PaymentScreen extends StatefulWidget {
  final PickupOrder order;
  final String? paymentLink; // from backend when method is card/bank
  final PaymentMethod paymentMethod;

  const PaymentScreen({
    super.key,
    required this.order,
    this.paymentLink,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _processing = false;
  bool _completed = false;
  String? _error;

  final fmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    if (_completed) return _SuccessScreen(order: widget.order);

    if (widget.paymentMethod == PaymentMethod.card &&
        widget.paymentLink != null) {
      return _FlutterwaveWebView(
        paymentLink: widget.paymentLink!,
        order: widget.order,
        onSuccess: (ref) => _verifyPayment(ref),
        onCancelled: () => Navigator.pop(context),
      );
    }

    // Wallet payment — show summary and confirm
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
        title: const Text('Confirm Payment',
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F4F0), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Color(0xFF2ECC71), size: 34),
            ),
            const SizedBox(height: 16),
            const Text('Pay with Wallet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 24),
            _SummaryTile(
                label: 'Order ID',
                value: '#${widget.order.id.substring(0, 8).toUpperCase()}'),
            _SummaryTile(label: 'Zone', value: widget.order.zoneName),
            _SummaryTile(
                label: 'Pickup Date',
                value:
                    '${DateFormat('EEE, MMM d').format(widget.order.scheduledPickupDate)} · ${widget.order.scheduledPickupTime}'),
            _SummaryTile(
                label: 'Items',
                value: '${widget.order.items.length} service(s)'),
            _SummaryTile(
                label: 'Subtotal',
                value: '₦${fmt.format(widget.order.subtotal)}'),
            _SummaryTile(
                label: 'Delivery',
                value: '₦${fmt.format(widget.order.deliveryFee)}'),
            const Divider(height: 28),
            _SummaryTile(
                label: 'Total Charged',
                value: '₦${fmt.format(widget.order.total)}',
                bold: true),
            const SizedBox(height: 8),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child:
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : _confirmWalletPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay ₦${fmt.format(widget.order.total)} from Wallet',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.warmGray)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWalletPayment() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      // Backend deducts wallet and marks order as paid
      final result = await ApiService().verifyPayment(
        transactionRef: 'wallet_${widget.order.id}',
        orderId: widget.order.id,
      );
      if (result.success) {
        setState(() {
          _processing = false;
          _completed = true;
        });
      } else {
        setState(() {
          _processing = false;
          _error = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _verifyPayment(String ref) async {
    setState(() => _processing = true);
    try {
      final result = await ApiService().verifyPayment(
        transactionRef: ref,
        orderId: widget.order.id,
      );
      setState(() {
        _processing = false;
        _completed = result.success;
      });
      if (!result.success) setState(() => _error = result.message);
    } catch (e) {
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }
}

// ─── FLUTTERWAVE WEBVIEW ──────────────────────────────────────────────────────

class _FlutterwaveWebView extends StatefulWidget {
  final String paymentLink;
  final PickupOrder order;
  final void Function(String ref) onSuccess;
  final VoidCallback onCancelled;

  const _FlutterwaveWebView({
    required this.paymentLink,
    required this.order,
    required this.onSuccess,
    required this.onCancelled,
  });

  @override
  State<_FlutterwaveWebView> createState() => _FlutterwaveWebViewState();
}

class _FlutterwaveWebViewState extends State<_FlutterwaveWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          // Detect Flutterwave redirect callbacks
          final url = req.url;
          if (url.contains('desiredwash://payment/success') ||
              url.contains('status=successful')) {
            // Extract transaction reference
            final uri = Uri.parse(url);
            final ref = uri.queryParameters['tx_ref'] ??
                uri.queryParameters['transaction_id'] ??
                '';
            widget.onSuccess(ref);
            return NavigationDecision.prevent;
          }
          if (url.contains('desiredwash://payment/cancel') ||
              url.contains('status=cancelled')) {
            widget.onCancelled();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentLink));
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
                    'Your order will not be confirmed if you cancel payment.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue Paying')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCancelled();
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
        ),
        title: const Text('Complete Payment',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.coral),
                SizedBox(height: 12),
                Text('Loading payment...',
                    style: TextStyle(color: AppColors.warmGray)),
              ],
            )),
        ],
      ),
    );
  }
}

// ─── SUCCESS SCREEN ───────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final PickupOrder order;
  const _SuccessScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated checkmark container
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 28),

              const Text('Pickup Scheduled! 🎉',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Your laundry pickup is booked for\n${DateFormat('EEEE, MMMM d').format(order.scheduledPickupDate)} at ${order.scheduledPickupTime}.',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.warmGray, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _SuccessRow('Order ID',
                        '#${order.id.substring(0, 8).toUpperCase()}'),
                    const SizedBox(height: 8),
                    _SuccessRow('Zone', order.zoneName),
                    const SizedBox(height: 8),
                    _SuccessRow('Total Paid',
                        '₦${NumberFormat('#,###').format(order.total)}'),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (r) => r.isFirst);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()));
                },
                child: const Text('View My Orders',
                    style: TextStyle(
                        color: AppColors.coral, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryTile(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.warmGray, fontSize: 14)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    fontSize: bold ? 16 : 14,
                    color: AppColors.darkText)),
          ],
        ),
      );
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  const _SuccessRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.warmGray, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.darkText)),
        ],
      );
}
