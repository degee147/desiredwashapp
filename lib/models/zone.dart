class Zone {
  final String id;
  final String name;
  final String area;
  final bool isAvailable;
  final double? deliveryFee;

  const Zone({
    required this.id,
    required this.name,
    required this.area,
    this.isAvailable = true,
    this.deliveryFee,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json['id'],
        name: json['name'],
        area: json['area'],
        isAvailable: json['is_available'] ?? true,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area,
        'is_available': isAvailable,
        'delivery_fee': deliveryFee,
      };
}

/// Port Harcourt zones — local seed, overridden by GET /zones on load
final List<Zone> portHarcourtZones = [
  Zone(id: 'z01', name: 'GRA Phase 1',   area: 'GRA',         deliveryFee: 500),
  Zone(id: 'z02', name: 'GRA Phase 2',   area: 'GRA',         deliveryFee: 500),
  Zone(id: 'z03', name: 'GRA Phase 3',   area: 'GRA',         deliveryFee: 500),
  Zone(id: 'z04', name: 'Old GRA',       area: 'GRA',         deliveryFee: 500),
  Zone(id: 'z05', name: 'Rumuola',       area: 'Rumuola',     deliveryFee: 600),
  Zone(id: 'z06', name: 'Rumuokoro',     area: 'Rumuola',     deliveryFee: 600),
  Zone(id: 'z07', name: 'Rumuodara',     area: 'Rumuola',     deliveryFee: 700),
  Zone(id: 'z08', name: 'Rumuibekwe',    area: 'Rumuola',     deliveryFee: 700),
  Zone(id: 'z09', name: 'Trans Amadi',   area: 'Trans Amadi', deliveryFee: 600),
  Zone(id: 'z10', name: 'D-Line',        area: 'D-Line',      deliveryFee: 500),
  Zone(id: 'z11', name: 'Peter Odili',   area: 'Peter Odili', deliveryFee: 600),
  Zone(id: 'z12', name: 'Ada George',    area: 'Ada George',  deliveryFee: 700),
  Zone(id: 'z13', name: 'Woji',          area: 'Woji',        deliveryFee: 700),
  Zone(id: 'z14', name: 'Eliozu',        area: 'Eliozu',      deliveryFee: 800),
  Zone(id: 'z15', name: 'Ozuoba',        area: 'Ozuoba',      deliveryFee: 800),
  Zone(id: 'z16', name: 'Choba',         area: 'Choba',       deliveryFee: 800),
  Zone(id: 'z17', name: 'NTA Road',      area: 'NTA Road',    deliveryFee: 600),
  Zone(id: 'z18', name: 'Garrison',      area: 'Garrison',    deliveryFee: 500),
  Zone(id: 'z19', name: 'Diobu',         area: 'Mile 1–3',    deliveryFee: 500),
  Zone(id: 'z20', name: 'Mile 1',        area: 'Mile 1–3',    deliveryFee: 500),
  Zone(id: 'z21', name: 'Mile 2',        area: 'Mile 1–3',    deliveryFee: 500),
  Zone(id: 'z22', name: 'Mile 3',        area: 'Mile 1–3',    deliveryFee: 500),
  Zone(id: 'z23', name: 'Borokiri',      area: 'Borokiri',    deliveryFee: 600),
  Zone(id: 'z24', name: 'Rumuche',       area: 'Rumuche',     deliveryFee: 900,  isAvailable: false),
  Zone(id: 'z25', name: 'Igwuruta',      area: 'Igwuruta',    deliveryFee: 1000, isAvailable: false),
];
