import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';






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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService();
      final balance = await api.getWalletBalance();
      final txns = await api.getWalletTransactions();
      setState(() { _balance = balance; _transactions = txns; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _showTopupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopUpSheet(
        onSuccess: (newBalance) {
          setState(() => _balance = newBalance);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

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
        title: const Text('My Wallet', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.darkText),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.warmGray)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(color: AppColors.coral))),
                  ],
                ))
              : RefreshIndicator(
                  color: AppColors.coral,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance card
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
                              BoxShadow(color: AppColors.coral.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                '₦${fmt.format(_balance ?? 0)}',
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _showTopupSheet,
                                  icon: const Icon(Icons.add_rounded, color: AppColors.coral),
                                  label: const Text('Top Up Wallet', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Text('Transaction History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkText)),
                        const SizedBox(height: 12),

                        if (_transactions.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('No transactions yet', style: TextStyle(color: Colors.grey.shade400)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100, indent: 60),
                              itemBuilder: (_, i) => _TransactionTile(tx: _transactions[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    final fmt = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F8F0) : const Color(0xFFFFECEC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF2ECC71) : AppColors.coral,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkText)),
                Text(DateFormat('MMM d, y · h:mm a').format(tx.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${fmt.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
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
  bool _showWebView = false;
  String? _paymentLink;

  static const _quickAmounts = [1000.0, 2000.0, 5000.0, 10000.0];

  @override
  Widget build(BuildContext context) {
    if (_showWebView && _paymentLink != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _TopUpWebView(
            paymentLink: _paymentLink!,
            onSuccess: (ref) async {
              Navigator.pop(context);
              try {
                final newBalance = await ApiService().verifyWalletTopup(ref);
                widget.onSuccess(newBalance);
              } catch (_) {}
            },
            onCancelled: () => setState(() => _showWebView = false),
          ),
        ),
      );
    }

    final fmt = NumberFormat('#,###');

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Top Up Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText)),
          const SizedBox(height: 20),

          // Quick amount buttons
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _quickAmounts.map((a) => GestureDetector(
              onTap: () => _amountController.text = a.toInt().toString(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text('₦${fmt.format(a)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: '₦ ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText, fontSize: 16),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _initiateTopup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Proceed to Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateTopup() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 100) {
      setState(() => _error = 'Enter a valid amount (min ₦100)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final link = await ApiService().initiateWalletTopup(amount);
      setState(() { _paymentLink = link; _showWebView = true; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }
}

class _TopUpWebView extends StatefulWidget {
  final String paymentLink;
  final void Function(String ref) onSuccess;
  final VoidCallback onCancelled;
  const _TopUpWebView({required this.paymentLink, required this.onSuccess, required this.onCancelled});

  @override
  State<_TopUpWebView> createState() => _TopUpWebViewState();
}

class _TopUpWebViewState extends State<_TopUpWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          final url = req.url;
          if (url.contains('status=successful') || url.contains('desiredwash://wallet/success')) {
            final uri = Uri.parse(url);
            final ref = uri.queryParameters['tx_ref'] ?? uri.queryParameters['transaction_id'] ?? '';
            widget.onSuccess(ref);
            return NavigationDecision.prevent;
          }
          if (url.contains('status=cancelled')) {
            widget.onCancelled();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentLink));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.darkText), onPressed: widget.onCancelled),
      title: const Text('Top Up Wallet', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700)),
      centerTitle: true,
    ),
    body: WebViewWidget(controller: _controller),
  );
}
