class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? zoneId;
  final String? zoneName;
  final double walletBalance;
  final String authProvider;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    this.zoneId,
    this.zoneName,
    this.walletBalance = 0.0,
    this.authProvider = 'email',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'].toString(),
        email: json['email'].toString(),
        phone: json['phone']?.toString(),
        address: json['address']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        zoneId: json['zone_id']?.toString(),
        zoneName: json['zone_name']?.toString(),
        walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
        authProvider: json['auth_provider']?.toString() ?? 'email',
        createdAt: DateTime.parse(json['created_at'].toString()),
      );

  AppUser copyWith({
    String? name,
    String? phone,
    String? address,
    String? zoneId,
    String? zoneName,
    double? walletBalance,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        avatarUrl: avatarUrl,
        zoneId: zoneId ?? this.zoneId,
        zoneName: zoneName ?? this.zoneName,
        walletBalance: walletBalance ?? this.walletBalance,
        authProvider: authProvider,
        createdAt: createdAt,
      );
}
