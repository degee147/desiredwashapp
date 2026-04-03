import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/app_colors.dart';
import '../../models/zone.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../zone/zone_picker_screen.dart';

// ─── SERVICE ITEM (UI state wrapper) ─────────────────────────────────────────

class _ServiceItem {
  final LaundryService service;
  int quantity;
  _ServiceItem(this.service) : quantity = 0;
}

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────

class SchedulePickupScreen extends StatefulWidget {
  const SchedulePickupScreen({super.key});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Zone? _selectedZone;
  DateTime? _selectedDate;
  String? _selectedTime;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  bool _submitting = false;

  // Services loaded from backend
  List<_ServiceItem> _serviceItems = [];
  bool _loadingServices = true;
  String? _servicesError;

  static const _timeSlots = [
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    // Pre-populate address from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.address != null && user!.address!.isNotEmpty) {
        _addressController.text = user.address!;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _servicesError = null;
    });
    try {
      final services = await ApiService().getServices();
      setState(() {
        _serviceItems = services.map((s) => _ServiceItem(s)).toList();
        _loadingServices = false;
      });
    } catch (e) {
      setState(() {
        _loadingServices = false;
        _servicesError = e.toString();
      });
    }
  }

  double get _subtotal =>
      _serviceItems.fold(0, (sum, s) => sum + s.service.price * s.quantity);
  double get _deliveryFee => _selectedZone?.deliveryFee ?? 0;
  double get _total => _subtotal + _deliveryFee;
  bool get _hasItems => _serviceItems.any((s) => s.quantity > 0);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
        title: const Text('Schedule Pickup',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location ──────────────────────────────────────────────────
              _sectionHeader('📍 Pickup Location'),
              const SizedBox(height: 10),
              _ZoneCard(
                zone: _selectedZone ??
                    (user?.zoneName != null
                        ? Zone(
                            id: user!.zoneId!, name: user.zoneName!, area: '')
                        : null),
                onTap: () async {
                  final zone = await Navigator.push<Zone>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZonePickerScreen(
                        currentZoneId: _selectedZone?.id ?? user?.zoneId,
                        returnOnly: true, // just return, don't save to profile
                      ),
                    ),
                  );
                  if (zone != null) setState(() => _selectedZone = zone);
                },
              ),
              const SizedBox(height: 10),
              _Card(
                child: TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter full pickup address…',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.home_outlined, color: AppColors.coral),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Services ──────────────────────────────────────────────────
              _sectionHeader('🧺 Select Services'),
              const SizedBox(height: 10),
              if (_loadingServices)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.coral),
                  ),
                )
              else if (_servicesError != null)
                _Card(
                  child: Column(
                    children: [
                      Text('Could not load services',
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadServices,
                        child: const Text('Retry',
                            style: TextStyle(color: AppColors.coral)),
                      ),
                    ],
                  ),
                )
              else
                _Card(
                  child: Column(
                    children: _serviceItems.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _ServiceRow(
                            item: item,
                            onIncrement: () => setState(() => item.quantity++),
                            onDecrement: () => setState(() {
                              if (item.quantity > 0) item.quantity--;
                            }),
                          ),
                          if (i < _serviceItems.length - 1)
                            Divider(height: 1, color: Colors.grey.shade100),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Date & Time ───────────────────────────────────────────────
              _sectionHeader('📅 Pickup Date & Time'),
              const SizedBox(height: 10),
              _DatePickerCard(
                selectedDate: _selectedDate,
                onSelect: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 10),
              _TimeSlotGrid(
                slots: _timeSlots,
                selected: _selectedTime,
                onSelect: (t) => setState(() => _selectedTime = t),
              ),

              const SizedBox(height: 24),

              // ── Payment ───────────────────────────────────────────────────
              _sectionHeader('💳 Payment Method'),
              const SizedBox(height: 10),
              _PaymentMethodCard(
                selected: _paymentMethod,
                walletBalance: user?.walletBalance ?? 0,
                total: _total,
                onChanged: (m) => setState(() => _paymentMethod = m),
              ),

              const SizedBox(height: 24),

              // ── Notes ─────────────────────────────────────────────────────
              _sectionHeader('📝 Special Notes (optional)'),
              const SizedBox(height: 10),
              _Card(
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special instructions for your laundry…',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Summary ───────────────────────────────────────────────────
              _OrderSummaryCard(
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                total: _total,
                zoneName: _selectedZone?.name ?? user?.zoneName,
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _ConfirmBar(
        total: _total,
        enabled: _hasItems &&
            _selectedDate != null &&
            _selectedTime != null &&
            (_selectedZone != null || user?.zoneId != null) &&
            _addressController.text.trim().isNotEmpty,
        loading: _submitting,
        onConfirm: _submit,
      ),
    );
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user!;
    final zone = _selectedZone ??
        Zone(
          id: user.zoneId!,
          name: user.zoneName ?? '',
          area: '',
          deliveryFee: _deliveryFee,
        );

    final items = _serviceItems
        .where((s) => s.quantity > 0)
        .map((s) => OrderItem(
              serviceId: s.service.id,
              serviceName: s.service.name,
              emoji: s.service.emoji,
              quantity: s.quantity,
              unitPrice: s.service.price,
            ))
        .toList();

    final address = _addressController.text.trim();

    setState(() => _submitting = true);

    try {
      final result = await ApiService().createOrder(
        zoneId: zone.id,
        address: address,
        items: items,
        scheduledPickupDate: _selectedDate!,
        scheduledPickupTime: _selectedTime!,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      if (_paymentMethod == PaymentMethod.wallet) {
        // Wallet payment — order is placed immediately, go to success screen
        _showOrderSuccess(result.order);
      } else {
        // Card payment — open Flutterwave WebView
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FlutterwavePaymentScreen(
              order: result.order,
              paymentLink: result.paymentLink!,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showOrderSuccess(PickupOrder order) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => _OrderSuccessScreen(order: order)),
      (route) => route.isFirst,
    );
  }

  Widget _sectionHeader(String text) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText));
}

// ─── FLUTTERWAVE PAYMENT WEBVIEW ──────────────────────────────────────────────

class _FlutterwavePaymentScreen extends StatefulWidget {
  final PickupOrder order;
  final String paymentLink;
  const _FlutterwavePaymentScreen(
      {required this.order, required this.paymentLink});

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

          // Flutterwave redirects back with status in the URL
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
      // Verify payment with backend
      await ApiService().initiatePayment(
        transactionRef: txRef,
        orderId: widget.order.id,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => _OrderSuccessScreen(order: widget.order),
        ),
        (route) => route.isFirst,
      );
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
                    'Your order has been placed but payment is incomplete. You can pay later from your orders.'),
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

// ─── ORDER SUCCESS SCREEN ─────────────────────────────────────────────────────

class _OrderSuccessScreen extends StatelessWidget {
  final PickupOrder order;
  const _OrderSuccessScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF2ECC71), size: 50),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed! 🎉',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText)),
              const SizedBox(height: 10),
              Text(
                'We\'ll pick up your laundry on\n${DateFormat('EEEE, MMM d').format(order.scheduledPickupDate)} at ${order.scheduledPickupTime}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.warmGray, height: 1.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    _SummaryRow('Order ID',
                        '#${order.id.substring(0, 8).toUpperCase()}'),
                    const SizedBox(height: 8),
                    _SummaryRow('Total', '₦${fmt.format(order.total)}',
                        bold: true),
                    const SizedBox(height: 8),
                    _SummaryRow(
                        'Payment',
                        order.paymentMethod == PaymentMethod.wallet
                            ? 'Wallet'
                            : 'Card'),
                    const SizedBox(height: 8),
                    _SummaryRow('Address', order.address),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SUB-WIDGETS ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
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
      );
}

class _ZoneCard extends StatelessWidget {
  final Zone? zone;
  final VoidCallback onTap;
  const _ZoneCard({this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: zone != null ? const Color(0xFFFFECEC) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: zone != null ? AppColors.coral : Colors.grey.shade200,
                width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.coral),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zone?.name ?? 'Tap to select your area',
                  style: TextStyle(
                    fontWeight:
                        zone != null ? FontWeight.w600 : FontWeight.normal,
                    color:
                        zone != null ? AppColors.darkText : AppColors.warmGray,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
}

class _ServiceRow extends StatelessWidget {
  final _ServiceItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _ServiceRow(
      {required this.item,
      required this.onIncrement,
      required this.onDecrement});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(item.service.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.darkText)),
                  Text(
                      '₦${NumberFormat('#,###').format(item.service.price)}/item',
                      style: const TextStyle(
                          color: AppColors.warmGray, fontSize: 12)),
                ],
              ),
            ),
            _Counter(
                count: item.quantity,
                onIncrement: onIncrement,
                onDecrement: onDecrement),
          ],
        ),
      );
}

class _Counter extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _Counter(
      {required this.count,
      required this.onIncrement,
      required this.onDecrement});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: count > 0
                    ? AppColors.coral.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove,
                  size: 16,
                  color: count > 0 ? AppColors.coral : Colors.grey.shade400),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$count',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.coral, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      );
}

class _DatePickerCard extends StatelessWidget {
  final DateTime? selectedDate;
  final void Function(DateTime) onSelect;
  const _DatePickerCard({this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i + 1)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected =
              selectedDate?.day == day.day && selectedDate?.month == day.month;
          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.coral : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 2),
                    style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white70 : AppColors.warmGray,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.darkText),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeSlotGrid extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final void Function(String) onSelect;
  const _TimeSlotGrid(
      {required this.slots, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: slots.map((slot) {
          final isSelected = selected == slot;
          return GestureDetector(
            onTap: () => onSelect(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.coral : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? AppColors.coral : Colors.grey.shade200),
              ),
              child: Text(slot,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.darkText,
                  )),
            ),
          );
        }).toList(),
      );
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod selected;
  final double walletBalance;
  final double total;
  final void Function(PaymentMethod) onChanged;
  const _PaymentMethodCard(
      {required this.selected,
      required this.walletBalance,
      required this.total,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final walletOk = walletBalance >= total;

    return _Card(
      child: Column(
        children: [
          _PaymentOption(
            icon: Icons.credit_card_rounded,
            label: 'Card / Bank Transfer',
            subtitle: 'Powered by Flutterwave',
            method: PaymentMethod.card,
            selected: selected,
            onTap: () => onChanged(PaymentMethod.card),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _PaymentOption(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Wallet Balance',
            subtitle: walletOk
                ? '₦${fmt.format(walletBalance)} available'
                : '₦${fmt.format(walletBalance)} — insufficient (need ₦${fmt.format(total)})',
            method: PaymentMethod.wallet,
            selected: selected,
            enabled: walletOk,
            onTap: walletOk ? () => onChanged(PaymentMethod.wallet) : null,
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final PaymentMethod method;
  final PaymentMethod selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.method,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selected;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.coral.withOpacity(0.1)
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon,
                    color: isSelected ? AppColors.coral : AppColors.warmGray,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.darkText)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: enabled
                                ? AppColors.warmGray
                                : Colors.red.shade400)),
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: selected,
                activeColor: AppColors.coral,
                onChanged: enabled ? (_) => onTap?.call() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? zoneName;
  const _OrderSummaryCard(
      {required this.subtotal,
      required this.deliveryFee,
      required this.total,
      this.zoneName});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2DFD8)),
      ),
      child: Column(
        children: [
          _SummaryRow('Subtotal', '₦${fmt.format(subtotal)}'),
          const SizedBox(height: 8),
          _SummaryRow('Delivery fee${zoneName != null ? ' ($zoneName)' : ''}',
              deliveryFee > 0 ? '₦${fmt.format(deliveryFee)}' : '—'),
          const Divider(height: 20, color: Color(0xFFB2DFD8)),
          _SummaryRow('Total', '₦${fmt.format(total)}', bold: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.warmGray,
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: bold ? 16 : 13,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

class _ConfirmBar extends StatelessWidget {
  final double total;
  final bool enabled;
  final bool loading;
  final VoidCallback onConfirm;
  const _ConfirmBar(
      {required this.total,
      required this.enabled,
      required this.loading,
      required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total',
                  style: TextStyle(color: AppColors.warmGray, fontSize: 12)),
              Text('₦${fmt.format(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.darkText)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (enabled && !loading) ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Pickup',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
