class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? zoneId;
  final String? zoneName;
  final double walletBalance;
  final String authProvider; // 'email' | 'google' | 'apple'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
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
    String? zoneId,
    String? zoneName,
    double? walletBalance,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl,
        zoneId: zoneId ?? this.zoneId,
        zoneName: zoneName ?? this.zoneName,
        walletBalance: walletBalance ?? this.walletBalance,
        authProvider: authProvider,
        createdAt: createdAt,
      );
}
