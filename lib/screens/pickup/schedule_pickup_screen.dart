import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/zone.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../zone/zone_picker_screen.dart';
import '../payment/payment_screen.dart';

class _LaundryService {
  final String id;
  final String name;
  final String emoji;
  final double price;
  int quantity;

  _LaundryService(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.price});
}

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

  final List<_LaundryService> _services = [
    _LaundryService(
        id: 'wash_fold', name: 'Wash & Fold', emoji: '👕', price: 1500),
    _LaundryService(
        id: 'dry_clean', name: 'Dry Cleaning', emoji: '🧥', price: 3500),
    _LaundryService(
        id: 'bedding', name: 'Bedding & Duvet', emoji: '🛏️', price: 4000),
    _LaundryService(
        id: 'shoe_clean', name: 'Shoe Cleaning', emoji: '👟', price: 2000),
    _LaundryService(
        id: 'iron_only', name: 'Iron Only', emoji: '♨️', price: 800),
    _LaundryService(id: 'curtains', name: 'Curtains', emoji: '🪟', price: 3000),
  ];

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

  double get _subtotal =>
      _services.fold(0, (sum, s) => sum + s.price * s.quantity);
  double get _deliveryFee => _selectedZone?.deliveryFee ?? 0;
  double get _total => _subtotal + _deliveryFee;
  bool get _hasItems => _services.any((s) => s.quantity > 0);

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
                            currentZoneId: _selectedZone?.id ?? user?.zoneId)),
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
              _sectionHeader('🧺 Select Services'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: _services.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Column(
                      children: [
                        _ServiceRow(
                          service: s,
                          onIncrement: () => setState(() => s.quantity++),
                          onDecrement: () => setState(() {
                            if (s.quantity > 0) s.quantity--;
                          }),
                        ),
                        if (i < _services.length - 1)
                          Divider(height: 1, color: Colors.grey.shade100),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
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
              _sectionHeader('💳 Payment Method'),
              const SizedBox(height: 10),
              _PaymentMethodCard(
                selected: _paymentMethod,
                walletBalance: user?.walletBalance ?? 0,
                total: _total,
                onChanged: (m) => setState(() => _paymentMethod = m),
              ),
              const SizedBox(height: 24),
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
              _OrderSummaryCard(
                subtotal: _subtotal,
                deliveryFee: _deliveryFee,
                total: _total,
                zoneName: _selectedZone?.name,
              ),
            ],
          ),
        ),
      ),

      // Sticky confirm button
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
          name: user.zoneName!,
          area: '',
          deliveryFee: _deliveryFee,
        );

    final items = _services
        .where((s) => s.quantity > 0)
        .map((s) => OrderItem(
              serviceId: s.id,
              serviceName: s.name,
              quantity: s.quantity,
              unitPrice: s.price,
            ))
        .toList();

    setState(() => _submitting = true);

    try {
      final result = await ApiService().createOrder(
        zoneId: zone.id,
        address: _addressController.text.trim(),
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

      // Navigate to payment screen
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              order: result.order,
              paymentLink: result.paymentLink,
              paymentMethod: _paymentMethod,
            ),
          ));
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _sectionHeader(String text) => Text(text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText));
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
  final _LaundryService service;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _ServiceRow(
      {required this.service,
      required this.onIncrement,
      required this.onDecrement});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(service.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.darkText)),
                  Text('₦${NumberFormat('#,###').format(service.price)}/item',
                      style: const TextStyle(
                          color: AppColors.warmGray, fontSize: 12)),
                ],
              ),
            ),
            _Counter(
                count: service.quantity,
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
                onChanged: enabled ? (v) => onTap?.call() : null,
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
        color: AppColors.mintGreen,
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
