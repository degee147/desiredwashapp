import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'zone/zone_picker_screen.dart';
import 'wallet/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingZone = false;

  @override
  void initState() {
    super.initState();
    // Refresh profile so wallet balance, zone, and address are always current
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final user = auth.user;

    final initials = user != null
        ? user.name
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : 'U';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Profile',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 24),
            _buildProfileHeader(user?.name ?? 'Guest', user?.phone ?? '',
                initials, user?.walletBalance ?? 0),
            const SizedBox(height: 28),
            _buildOrderHistory(context, orders),
            const SizedBox(height: 28),
            _buildAccountSettings(context, auth),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(
      String name, String phone, String initials, double walletBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4D0), Color(0xFFFFD0E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7B5EA7),
                      fontSize: 22)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text(phone.isNotEmpty ? phone : 'No phone set',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.warmGray)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatBadge('₦${_fmt(walletBalance)}', 'Wallet'),
                    const SizedBox(width: 10),
                    const StatBadge('4.8★', 'Rating'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ── Order history ───────────────────────────────────────────────────────────

  Widget _buildOrderHistory(BuildContext context, OrderProvider orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order History',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText)),
        const SizedBox(height: 14),
        if (orders.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          )
        else if (orders.orders.isEmpty)
          const Text('No orders yet — schedule your first pickup!',
              style: TextStyle(fontSize: 13, color: AppColors.warmGray))
        else
          ...orders.orders.take(3).map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HistoryCard(
                  '#${o.id.substring(0, 8).toUpperCase()}',
                  o.items.isNotEmpty ? o.items.first.serviceName : 'Laundry',
                  '${o.scheduledPickupDate.day} ${_month(o.scheduledPickupDate.month)}',
                  '₦${_fmtFull(o.total)}',
                  _statusLabel(o.status),
                  _statusColor(o.status),
                ),
              )),
      ],
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
      default:
        return 'In Progress';
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

  String _fmtFull(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _month(int m) => const [
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
      ][m];

  // ── Account settings ────────────────────────────────────────────────────────

  Widget _buildAccountSettings(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              // Saved Addresses → Zone picker
              GestureDetector(
                onTap: () => _changeZone(context, auth),
                child: SettingRow(
                  Icons.location_on_rounded,
                  _savingZone
                      ? 'Saving…'
                      : (auth.user?.zoneName != null
                          ? 'Area: ${auth.user!.zoneName}'
                          : 'Set Your Area'),
                  AppColors.coral,
                ),
              ),
              CardDivider(),
              // Wallet
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WalletScreen())),
                child: const SettingRow(Icons.account_balance_wallet_rounded,
                    'Wallet & Payments', AppColors.softBlue),
              ),
              CardDivider(),
              const SettingRow(Icons.notifications_rounded, 'Notifications',
                  AppColors.peach),
              CardDivider(),
              const SettingRow(
                  Icons.help_rounded, 'Help & Support', AppColors.lavender),
              CardDivider(),
              // Sign Out
              GestureDetector(
                onTap: () => _signOut(context, auth),
                child: const SettingRow(
                    Icons.logout_rounded, 'Sign Out', Color(0xFFFFD0D0)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changeZone(BuildContext context, AuthProvider auth) async {
    final zone = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ZonePickerScreen(currentZoneId: auth.user?.zoneId)));
    if (zone == null || !mounted) return;

    setState(() => _savingZone = true);
    try {
      final updated =
          await context.read<ApiService>().updateProfile(zoneId: zone.id);
      auth.updateLocalUser(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save area: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingZone = false);
    }
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('You will need to log in again to place orders.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await auth.logout();
      // _AppGate watches auth state and will redirect to WelcomeScreen
    }
  }
}

// ── Stat Badge — unchanged ─────────────────────────────────────────────────────
class StatBadge extends StatelessWidget {
  final String value, label;
  const StatBadge(this.value, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.darkText)),
            TextSpan(
                text: ' $label',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.warmGray)),
          ],
        ),
      ),
    );
  }
}

// ── History Card — unchanged ───────────────────────────────────────────────────
class HistoryCard extends StatelessWidget {
  final String id, service, date, price, status;
  final Color statusColor;

  const HistoryCard(this.id, this.service, this.date, this.price, this.status,
      this.statusColor,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_laundry_service_rounded,
                color: AppColors.coral, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.darkText)),
                Text('$id • $date',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.warmGray)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.darkText)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D60))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Setting Row — unchanged ────────────────────────────────────────────────────
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;

  const SettingRow(this.icon, this.label, this.iconBg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18, color: AppColors.darkText.withOpacity(0.7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.darkText)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.warmGray, size: 20),
        ],
      ),
    );
  }
}
