import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      const _TrackStep('Order Confirmed', 'Feb 23, 8:15 AM', true, true),
      const _TrackStep('Rider on the Way', 'Feb 23, 8:45 AM', true, true),
      const _TrackStep('Items Picked Up', 'Feb 23, 9:10 AM', true, false),
      const _TrackStep('Being Washed', 'Est. 11:00 AM', false, false),
      const _TrackStep('Out for Delivery', 'Est. 3:00 PM', false, false),
      const _TrackStep('Delivered!', 'Est. 4:00 PM', false, false),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track Order',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 4),
            const Text('Live updates for your laundry',
                style: TextStyle(fontSize: 14, color: AppColors.warmGray)),
            const SizedBox(height: 24),
            _buildOrderCard(),
            const SizedBox(height: 28),
            _buildRiderCard(),
            const SizedBox(height: 28),
            const Text('Timeline',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText)),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (i) {
              return _buildTimelineStep(steps[i], i == steps.length - 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #BUB-2847',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.darkText)),
                    SizedBox(height: 4),
                    Text('Wash & Fold • 3 items',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.warmGray)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('In Progress',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.coral)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: AppColors.cream,
              valueColor: AlwaysStoppedAnimation(AppColors.coral),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3 of 6 steps complete',
                  style: TextStyle(fontSize: 11, color: AppColors.warmGray)),
              Text('50%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coral)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('AO',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2665A0),
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adebayo Okafor',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.darkText)),
                Text('Your rider • ⭐ 4.9',
                    style: TextStyle(fontSize: 12, color: AppColors.warmGray)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(_TrackStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: step.done
                    ? AppColors.coral
                    : step.active
                        ? AppColors.peach
                        : AppColors.cream,
                shape: BoxShape.circle,
                border: step.active && !step.done
                    ? Border.all(color: AppColors.coral, width: 2)
                    : null,
              ),
              child: Icon(
                step.done
                    ? Icons.check_rounded
                    : step.active
                        ? Icons.circle
                        : Icons.circle_outlined,
                color: step.done
                    ? Colors.white
                    : step.active
                        ? AppColors.coral
                        : AppColors.warmGray.withOpacity(0.5),
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 48,
                  color: step.done ? AppColors.coral : AppColors.cream),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: step.done || step.active
                          ? AppColors.darkText
                          : AppColors.warmGray)),
              const SizedBox(height: 2),
              Text(step.time,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.warmGray)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackStep {
  final String label, time;
  final bool done, active;
  const _TrackStep(this.label, this.time, this.done, this.active);
}
