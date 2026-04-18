import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import 'zone/zone_picker_screen.dart';
import 'notifications/notifications_screen.dart';
import 'wallet/wallet_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _savingZone = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await context.read<AuthProvider>().refreshProfile();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
      child: RefreshIndicator(
        color: AppColors.coral,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          // Always scrollable so pull-to-refresh works even if content is short
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row with title + refresh button ──────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text('My Profile',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText)),
                  ),
                  _RefreshButton(
                    refreshing: _refreshing,
                    onTap: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Profile header with wallet balance ──────────────────────────
              _buildProfileHeader(context, user?.name ?? 'Guest',
                  user?.phone ?? '', initials, user?.walletBalance ?? 0),
              const SizedBox(height: 28),

              // ── Account settings ────────────────────────────────────────────
              _buildAccountSettings(context, auth),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context, String name, String phone,
      String initials, double walletBalance) {
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
          Stack(
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
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  ),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 11),
                  ),
                ),
              ),
            ],
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

  // ── Account settings ────────────────────────────────────────────────────────

  Widget _buildAccountSettings(BuildContext context, AuthProvider auth) {
    final unread = context.watch<NotificationProvider>().unreadCount;

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
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
                child: const SettingRow(
                    Icons.edit_rounded, 'Edit Profile', AppColors.lavender),
              ),
              CardDivider(),
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
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WalletScreen())),
                child: const SettingRow(Icons.account_balance_wallet_rounded,
                    'Wallet & Payments', AppColors.softBlue),
              ),
              CardDivider(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: SettingRow(
                  Icons.notifications_rounded,
                  'Notifications',
                  AppColors.peach,
                  badge: unread > 0 ? unread : null,
                ),
              ),
              CardDivider(),
              const SettingRow(
                  Icons.help_rounded, 'Help & Support', AppColors.lavender),
              CardDivider(),
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
    }
  }
}

// ─── REFRESH BUTTON ───────────────────────────────────────────────────────────

class _RefreshButton extends StatelessWidget {
  final bool refreshing;
  final VoidCallback onTap;

  const _RefreshButton({required this.refreshing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: refreshing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.coral, strokeWidth: 2.2),
                )
              : const Icon(Icons.refresh_rounded,
                  color: AppColors.coral, size: 20),
        ),
      ),
    );
  }
}

// ─── STAT BADGE ───────────────────────────────────────────────────────────────

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

// ─── SETTING ROW ──────────────────────────────────────────────────────────────

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final int? badge;

  const SettingRow(this.icon, this.label, this.iconBg, {super.key, this.badge});

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
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.coral,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.warmGray, size: 20),
        ],
      ),
    );
  }
}
