import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/order_screen.dart';
import '../screens/track_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/zone/zone_picker_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Using a getter so IndexedStack rebuilds with correct types —
  // OrderScreen is now stateful so can't be const in a list literal.
  List<Widget> get _pages => const [
        HomeScreen(),
        OrderScreen(),
        TrackScreen(),
        ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    // If the user has no zone set yet, prompt them to pick one after login
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptZone());
  }

  void _maybePromptZone() async {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.zoneId == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ZonePickerScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs alive (preserves scroll position etc.)
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── BottomNav — identical to original, just extracted here ──────────────────

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.local_laundry_service_rounded, 'Order'),
      (Icons.track_changes_rounded, 'Track'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = currentIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.coral : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i].$1,
                        color: selected ? Colors.white : AppColors.warmGray,
                        size: 22,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[i].$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
