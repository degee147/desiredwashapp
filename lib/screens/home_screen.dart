import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildActiveBanner(),
            const SizedBox(height: 28),
            _buildServicesGrid(),
            const SizedBox(height: 28),
            _buildPromo(),
            const SizedBox(height: 28),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning ☀️',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.warmGray,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Sarah Johnson',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText)),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('SJ',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B5EA7),
                    fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7D5C), Color(0xFFFFB085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.coral.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Active Order',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 10),
                const Text('Order #BUB-2847',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Pickup in 25 mins • 3 items',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final services = [
      ('Wash & Fold', Icons.water_drop_rounded, AppColors.softBlue),
      ('Dry Clean', Icons.dry_cleaning_rounded, AppColors.lavender),
      ('Iron Only', Icons.iron_rounded, AppColors.mintGreen),
      ('Express', Icons.bolt_rounded, AppColors.cream),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Our Services',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: services
              .map((s) => ServiceCard(label: s.$1, icon: s.$2, bgColor: s.$3))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPromo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mintGreen, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('First Order Free!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.darkText)),
                const SizedBox(height: 4),
                Text('Use code BUBBLY25 for 25% off your next order',
                    style: TextStyle(fontSize: 12, color: AppColors.warmGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            Text('See all',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 14),
        OrderTile(
            id: '#BUB-2831',
            service: 'Wash & Fold',
            status: 'Delivered',
            date: 'Feb 20',
            statusColor: AppColors.mintGreen),
        const SizedBox(height: 10),
        OrderTile(
            id: '#BUB-2819',
            service: 'Dry Clean • 2 items',
            status: 'Delivered',
            date: 'Feb 15',
            statusColor: AppColors.mintGreen),
      ],
    );
  }
}

// ── Service Card (home-specific) ──────────────────────────────────────────────
class ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;

  const ServiceCard(
      {super.key,
      required this.label,
      required this.icon,
      required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.darkText.withOpacity(0.75), size: 28),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.darkText)),
        ],
      ),
    );
  }
}
