import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildProfileHeader(),
            const SizedBox(height: 28),
            _buildOrderHistory(),
            const SizedBox(height: 28),
            _buildAccountSettings(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
            child: const Center(
              child: Text('SJ',
                  style: TextStyle(
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
                const Text('Sarah Johnson',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text('+234 812 345 6789',
                    style: TextStyle(fontSize: 13, color: AppColors.warmGray)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatBadge('12', 'Orders'),
                    const SizedBox(width: 10),
                    StatBadge('4.8★', 'Rating'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order History',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText)),
        const SizedBox(height: 14),
        HistoryCard('#BUB-2831', 'Wash & Fold', 'Feb 20', '₦4,500', 'Delivered',
            AppColors.mintGreen),
        const SizedBox(height: 10),
        HistoryCard('#BUB-2819', 'Dry Clean • 2 items', 'Feb 15', '₦6,000',
            'Delivered', AppColors.mintGreen),
        const SizedBox(height: 10),
        HistoryCard('#BUB-2801', 'Iron Only • 5 items', 'Feb 8', '₦4,000',
            'Delivered', AppColors.mintGreen),
      ],
    );
  }

  Widget _buildAccountSettings() {
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
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              SettingRow(Icons.location_on_rounded, 'Saved Addresses',
                  AppColors.coral),
              CardDivider(),
              SettingRow(
                  Icons.payment_rounded, 'Payment Methods', AppColors.softBlue),
              CardDivider(),
              SettingRow(Icons.notifications_rounded, 'Notifications',
                  AppColors.peach),
              CardDivider(),
              SettingRow(
                  Icons.help_rounded, 'Help & Support', AppColors.lavender),
              CardDivider(),
              SettingRow(
                  Icons.logout_rounded, 'Sign Out', const Color(0xFFFFD0D0)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────
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
                style: TextStyle(fontSize: 11, color: AppColors.warmGray)),
          ],
        ),
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────
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
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3))
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
                    style: TextStyle(fontSize: 11, color: AppColors.warmGray)),
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

// ── Setting Row ───────────────────────────────────────────────────────────────
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
          Icon(Icons.chevron_right_rounded,
              color: AppColors.warmGray, size: 20),
        ],
      ),
    );
  }
}
