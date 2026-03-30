import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/zone.dart';
import '../../services/api_service.dart';

/// Searchable zone list for Port Harcourt.
/// Push this screen and await the result — returns the selected [Zone].
class ZonePickerScreen extends StatefulWidget {
  final String? currentZoneId;
  const ZonePickerScreen({super.key, this.currentZoneId});

  @override
  State<ZonePickerScreen> createState() => _ZonePickerScreenState();
}

class _ZonePickerScreenState extends State<ZonePickerScreen> {
  List<Zone> _allZones = [];
  List<Zone> _filtered = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentZoneId;
    _loadZones();
  }

  Future<void> _loadZones() async {
    // Seed locally first so picker is instant even offline
    setState(() {
      _allZones = portHarcourtZones;
      _filtered = portHarcourtZones;
      _loading = false;
    });
    try {
      final zones = await ApiService().getZones();
      setState(() {
        _allZones = zones;
        _filtered = zones;
      });
    } catch (_) {}
  }

  void _search(String q) {
    setState(() {
      _filtered = _allZones
          .where((z) =>
              z.name.toLowerCase().contains(q.toLowerCase()) ||
              z.area.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Map<String, List<Zone>> get _grouped {
    final map = <String, List<Zone>>{};
    for (final z in _filtered) {
      map.putIfAbsent(z.area, () => []).add(z);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Your Area',
            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search area or zone…',
                hintStyle: TextStyle(color: AppColors.warmGray.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.warmGray),
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Coming soon notice
          if (_allZones.any((z) => !z.isAvailable))
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 15, color: Color(0xFF856404)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Greyed-out zones are coming soon.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF856404))),
                  ),
                ],
              ),
            ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.coral)))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: _grouped.entries.map((entry) => _AreaSection(
                  area: entry.key,
                  zones: entry.value,
                  selectedId: _selectedId,
                  onSelect: (z) {
                    if (!z.isAvailable) return;
                    setState(() => _selectedId = z.id);
                  },
                )).toList(),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _selectedId == null
                      ? null
                      : () => Navigator.pop(
                          context, _allZones.firstWhere((z) => z.id == _selectedId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    disabledBackgroundColor: AppColors.cream,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedId == null ? 'Select an area to continue' : 'Confirm Area',
                    style: TextStyle(
                      color: _selectedId == null ? AppColors.warmGray : Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSection extends StatelessWidget {
  final String area;
  final List<Zone> zones;
  final String? selectedId;
  final void Function(Zone) onSelect;
  const _AreaSection({required this.area, required this.zones, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(area.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.warmGray, letterSpacing: 1.2)),
      ),
      ...zones.map((zone) {
        final isSelected = zone.id == selectedId;
        final unavailable = !zone.isAvailable;
        return Opacity(
          opacity: unavailable ? 0.4 : 1.0,
          child: GestureDetector(
            onTap: () => onSelect(zone),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.peach.withOpacity(0.4) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected ? AppColors.coral : Colors.transparent, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: isSelected ? AppColors.coral : AppColors.warmGray, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: unavailable ? AppColors.warmGray : AppColors.darkText)),
                        if (unavailable)
                          Text('Coming soon',
                              style: TextStyle(fontSize: 11, color: AppColors.warmGray.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  if (zone.deliveryFee != null && !unavailable)
                    Text('₦${zone.deliveryFee!.toInt()} delivery',
                        style: TextStyle(fontSize: 12, color: AppColors.warmGray)),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded, color: AppColors.coral, size: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    ],
  );
}
