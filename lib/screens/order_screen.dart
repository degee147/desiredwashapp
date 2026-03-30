import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import 'pickup/schedule_pickup_screen.dart';

// OrderScreen is the "Order" tab in the bottom nav.
// It now acts as a launcher to the full SchedulePickupScreen,
// while keeping the original UI design intact as the entry point.

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _selectedService = 0;

  final services = [
    ('Wash & Fold',  '₦1,500/kg',   Icons.water_drop_rounded,  AppColors.softBlue),
    ('Dry Clean',    '₦3,000/item', Icons.dry_cleaning_rounded, AppColors.lavender),
    ('Iron Only',    '₦800/item',   Icons.iron_rounded,         AppColors.mintGreen),
    ('Express',      '₦2,500/kg',   Icons.bolt_rounded,         AppColors.cream),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule Pickup',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 4),
            Text("We'll come to you!",
                style: TextStyle(fontSize: 14, color: AppColors.warmGray)),
            const SizedBox(height: 28),

            // Zone indicator — shows current area or prompts to set one
            _ZoneIndicator(
              zoneName: user?.zoneName,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SchedulePickupScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SectionLabel('Choose Service'),
            const SizedBox(height: 12),
            _buildServiceSelector(),
            const SizedBox(height: 32),

            // Main CTA — opens the full scheduling flow
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SchedulePickupScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Schedule Pickup',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = services[i];
          final selected = _selectedService == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedService = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.coral : s.$4,
                borderRadius: BorderRadius.circular(18),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppColors.coral.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6))
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(s.$3,
                      color: selected
                          ? Colors.white
                          : AppColors.darkText.withOpacity(0.7),
                      size: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : AppColors.darkText)),
                      Text(s.$2,
                          style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.warmGray)),
                    ],
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

// ─── Zone indicator banner ─────────────────────────────────────────────────

class _ZoneIndicator extends StatelessWidget {
  final String? zoneName;
  final VoidCallback onTap;

  const _ZoneIndicator({this.zoneName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: zoneName != null
              ? AppColors.peach.withOpacity(0.35)
              : AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: zoneName != null ? AppColors.coral : AppColors.peach,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded,
                color: AppColors.coral, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                zoneName != null
                    ? 'Pickup from: $zoneName'
                    : 'Tap to select your area in Port Harcourt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: zoneName != null
                      ? AppColors.darkText
                      : AppColors.warmGray,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.warmGray, size: 20),
          ],
        ),
      ),
    );
  }
}
