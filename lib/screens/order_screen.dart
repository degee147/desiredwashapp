import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/shared_widgets.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _selectedService = 0;
  String _selectedDate = 'Tomorrow';
  String _selectedTime = '9:00 AM';

  final services = [
    ('Wash & Fold', '₦1,500/kg', Icons.water_drop_rounded, AppColors.softBlue),
    (
      'Dry Clean',
      '₦3,000/item',
      Icons.dry_cleaning_rounded,
      AppColors.lavender
    ),
    ('Iron Only', '₦800/item', Icons.iron_rounded, AppColors.mintGreen),
    ('Express', '₦2,500/kg', Icons.bolt_rounded, AppColors.peach),
  ];

  final dates = ['Today', 'Tomorrow', 'Wed 26', 'Thu 27', 'Fri 28'];
  final times = ['8:00 AM', '9:00 AM', '11:00 AM', '2:00 PM', '5:00 PM'];

  @override
  Widget build(BuildContext context) {
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
            const SectionLabel('Choose Service'),
            const SizedBox(height: 12),
            _buildServiceSelector(),
            const SizedBox(height: 24),
            const SectionLabel('Pickup Date'),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 24),
            const SectionLabel('Pickup Time'),
            const SizedBox(height: 12),
            _buildTimeSelector(),
            const SizedBox(height: 24),
            const SectionLabel('Pickup Address'),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 32),
            _buildConfirmButton(),
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

  Widget _buildDateSelector() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final selected = _selectedDate == dates[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = dates[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.darkText : AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Text(dates[i],
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.warmGray)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: times.map((t) {
        final selected = _selectedTime == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.peach : AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? AppColors.coral : Colors.transparent,
                  width: 1.5),
            ),
            child: Text(t,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? AppColors.darkText : AppColors.warmGray)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.coral, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('12 Maitama Close',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.darkText)),
                Text('Abuja, FCT • Home',
                    style: TextStyle(fontSize: 12, color: AppColors.warmGray)),
              ],
            ),
          ),
          Text('Change',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.coral,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
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
            Text('Confirm Pickup',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
