import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────

class WalletScreen extends StatefulWidget {
  final bool embedded;
  const WalletScreen({super.key, this.embedded = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double? _balance;
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  String? _error;
  bool _balanceVisible = true;
  String? _contactPhone;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getWalletBalance(),
        api.getWalletTransactions(),
        api.getContactPhone(),
      ]);
      if (!mounted) return;
      final balance = results[0] as double;
      final txns = results[1] as List<WalletTransaction>;
      final phone = results[2] as String;
      // Sync balance into AuthProvider so other screens see it too
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<AuthProvider>()
            .updateLocalUser(user.copyWith(walletBalance: balance));
      }
      setState(() {
        _balance = balance;
        _transactions = txns;
        _contactPhone = phone;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showTopupSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopUpSheet(
        onSuccess: (newBalance) {
          if (!mounted) return;
          final user = context.read<AuthProvider>().user;
          if (user != null) {
            context.read<AuthProvider>().updateLocalUser(
                  user.copyWith(walletBalance: newBalance),
                );
          }
          // 🔔 Pull fresh notifications — wallet_topup will be there
          context.read<NotificationProvider>().fetchNotifications();
          setState(() => _balance = newBalance);
          _loadData(); // reload transactions too
        },
      ),
    );
  }

  Future<void> _callToFund() async {
    final phone = _contactPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch dialer for $phone'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final balance = _balance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.darkText),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text('My Wallet',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.darkText),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.coral))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Balance Card ───────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.coral, AppColors.peach],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.coral.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Wallet Balance',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _balanceVisible = !_balanceVisible),
                                    child: Icon(
                                      _balanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _balanceVisible
                                    ? '₦${fmt.format(balance)}'
                                    : '₦ ••••••',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: _showTopupSheet,
                                        icon: const Icon(Icons.add_rounded,
                                            color: AppColors.coral, size: 18),
                                        label: const Text('Top Up',
                                            style: TextStyle(
                                                color: AppColors.coral,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: _contactPhone != null
                                            ? _callToFund
                                            : null,
                                        icon: const Icon(Icons.phone_rounded,
                                            color: Colors.white, size: 18),
                                        label: const Text('Call to Fund',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.white.withOpacity(0.25),
                                          disabledBackgroundColor:
                                              Colors.white.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: const BorderSide(
                                                color: Colors.white54,
                                                width: 1.5),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Transaction History ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transaction History',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText)),
                            if (_transactions.isNotEmpty)
                              Text('${_transactions.length} total',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.warmGray)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_transactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.receipt_long_outlined,
                                        size: 34, color: Colors.grey.shade300),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('No transactions yet',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('Top up your wallet to get started',
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
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
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                  indent: 68),
                              itemBuilder: (_, i) =>
                                  _TransactionTile(tx: _transactions[i]),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ─── TRANSACTION TILE ─────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return const Color(0xFF2ECC71);
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    final fmt = NumberFormat('#,###');

    final statusColor = _statusColor(tx.status);
    final statusLabel = _statusLabel(tx.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isCredit ? const Color(0xFFE8F8F0) : const Color(0xFFFFECEC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF2ECC71) : AppColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.darkText,
                  ),
                ),

                const SizedBox(height: 4),

                // STATUS BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  DateFormat('MMM d, y · h:mm a')
                      .format(tx.createdAt.toLocal()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),

                if (tx.reference != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: tx.reference!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reference copied'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      tx.reference!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.coral.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // AMOUNT
          Text(
            '${isCredit ? '+' : '-'}₦${fmt.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isCredit ? const Color(0xFF2ECC71) : AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TOP-UP BOTTOM SHEET ─────────────────────────────────────────────────────

class _TopUpSheet extends StatefulWidget {
  final void Function(double newBalance) onSuccess;
  const _TopUpSheet({required this.onSuccess});

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountController = TextEditingController();
  bool _loading = false;
  String? _error;
  double? _selectedQuick;

  static const _quickAmounts = [1000.0, 2000.0, 5000.0, 10000.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuick(double amount) {
    setState(() {
      _selectedQuick = amount;
      _amountController.text = amount.toInt().toString();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            const Text('Top Up Wallet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Text('Funds are added instantly after payment.',
                style: TextStyle(fontSize: 13, color: AppColors.warmGray)),
            const SizedBox(height: 20),

            // Quick amounts
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((a) {
                final isSelected = _selectedQuick == a;
                return GestureDetector(
                  onTap: () => _selectQuick(a),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.coral.withOpacity(0.1)
                          : AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.coral
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1),
                    ),
                    child: Text(
                      '₦${fmt.format(a)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.coral
                              : AppColors.darkText),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom amount field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _selectedQuick = null),
              decoration: InputDecoration(
                hintText: 'Or enter custom amount',
                prefixText: '₦ ',
                prefixStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                    fontSize: 16),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.coral, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 15, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Text(_error!,
                      style:
                          TextStyle(color: Colors.red.shade600, fontSize: 13)),
                ],
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _initiateTopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Proceed to Payment',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateTopup() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 100) {
      setState(() => _error = 'Enter a valid amount (minimum ₦100)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final link = await ApiService().initiateWalletTopup(amount);
      if (!mounted) return;
      setState(() => _loading = false);

      // Open payment WebView as a full-screen route
      final newBalance = await Navigator.push<double>(
        context,
        MaterialPageRoute(
          builder: (_) => _TopUpWebViewScreen(
            paymentLink: link,
            amount: amount,
          ),
          fullscreenDialog: true,
        ),
      );

      if (newBalance != null && mounted) {
        Navigator.pop(context); // close the sheet
        widget.onSuccess(newBalance);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
}

// ─── TOP-UP WEBVIEW (full screen) ────────────────────────────────────────────

class _TopUpWebViewScreen extends StatefulWidget {
  final String paymentLink;
  final double amount;
  const _TopUpWebViewScreen({required this.paymentLink, required this.amount});

  @override
  State<_TopUpWebViewScreen> createState() => _TopUpWebViewScreenState();
}

class _TopUpWebViewScreenState extends State<_TopUpWebViewScreen> {
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
          debugPrint('💳 Wallet WebView: $url');

          if (url.contains('status=successful') ||
              url.contains('status=completed')) {
            final uri = Uri.parse(url);
            final ref = uri.queryParameters['tx_ref'] ??
                uri.queryParameters['transaction_id'] ??
                uri.queryParameters['reference'] ??
                '';
            _onPaymentSuccess(ref);
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

  Future<void> _onPaymentSuccess(String ref) async {
    if (_verifying) return;
    setState(() => _verifying = true);

    debugPrint('Ref to verify: $ref');

    try {
      final newBalance = await ApiService().verifyWalletTopup(ref);
      if (!mounted) return;
      // Pop back to sheet with new balance
      Navigator.pop(context, newBalance);
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onPaymentCancelled() {
    Navigator.pop(context); // pop without a balance = cancelled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment was cancelled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Cancel Top-Up?',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                content: Text(
                    'Your ₦${fmt.format(widget.amount)} top-up will not be processed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Paying'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close webview
                    },
                    child: Text('Leave',
                        style: TextStyle(color: Colors.red.shade600)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Column(
          children: [
            const Text('Top Up Wallet',
                style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('₦${fmt.format(widget.amount)}',
                style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
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
                    SizedBox(height: 6),
                    Text('Please wait…',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── ERROR STATE ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.warmGray, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}
