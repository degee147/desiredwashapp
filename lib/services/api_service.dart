import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/zone.dart';
import '../models/order.dart';

/// Central API service — all HTTP calls go here.
/// Replace [baseUrl] with your actual backend URL.
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const String baseUrl = 'https://desiredwash.com/api/v1';

  String? _authToken;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400)
      throw ApiException(data['message'] ?? 'Server error', res.statusCode);
    return data;
  }

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400)
      throw ApiException(data['message'] ?? 'Server error', res.statusCode);
    return data;
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// POST /auth/signup
  /// Body: { name, email, password, phone? }
  /// Returns: { user, token }
  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    });
    return AuthResult.fromJson(data);
  }

  /// POST /auth/login
  /// Body: { email, password }
  /// Returns: { user, token }
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(data);
  }

  /// POST /auth/social
  /// Body: { provider: 'google'|'apple', id_token, name?, email?, avatar_url? }
  /// Returns: { user, token }
  Future<AuthResult> signInWithSocial({
    required String provider,
    required String idToken,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    final data = await _post('/auth/social', {
      'provider': provider,
      'id_token': idToken,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return AuthResult.fromJson(data);
  }

  /// POST /auth/forgot-password
  /// Body: { email }
  Future<void> forgotPassword(String email) async {
    await _post('/auth/forgot-password', {'email': email});
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────

  /// GET /profile
  Future<AppUser> getProfile() async {
    final data = await _get('/profile');
    return AppUser.fromJson(data['user']);
  }

  /// PATCH /profile
  /// Body: { name?, phone?, zone_id? }
  Future<AppUser> updateProfile(
      {String? name, String? phone, String? zoneId}) async {
    final data = await _post('/profile/update', {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (zoneId != null) 'zone_id': zoneId,
    });
    return AppUser.fromJson(data['user']);
  }

  // ─── ZONES ────────────────────────────────────────────────────────────────

  /// GET /zones
  /// Returns list of available zones in Port Harcourt
  Future<List<Zone>> getZones() async {
    final data = await _get('/zones');
    return (data['zones'] as List).map((e) => Zone.fromJson(e)).toList();
  }

  /// Saves the user's selected zone via PATCH /profile/update.
  /// Returns the updated [AppUser] so the caller can sync the provider.
  Future<AppUser> saveUserZone(String zoneId) async {
    return updateProfile(zoneId: zoneId);
  }

  // ─── SERVICES ─────────────────────────────────────────────────────────────

  /// GET /services
  Future<List<LaundryService>> getServices() async {
    final data = await _get('/services');
    return (data['services'] as List)
        .map((e) => LaundryService.fromJson(e))
        .toList();
  }

  // ─── ORDERS ───────────────────────────────────────────────────────────────

  /// POST /orders
  /// Body: { zone_id, address, items, scheduled_pickup_date,
  ///         scheduled_pickup_time, payment_method, notes? }
  /// Returns: { order, payment_link? }
  Future<CreateOrderResult> createOrder({
    required String zoneId,
    required String address,
    required List<OrderItem> items,
    required DateTime scheduledPickupDate,
    required String scheduledPickupTime,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final data = await _post('/orders', {
      'zone_id': zoneId,
      'address': address,
      'items': items.map((i) => i.toJson()).toList(),
      'scheduled_pickup_date':
          scheduledPickupDate.toIso8601String().split('T').first,
      'scheduled_pickup_time': scheduledPickupTime,
      'payment_method':
          paymentMethod == PaymentMethod.wallet ? 'wallet' : 'card',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return CreateOrderResult.fromJson(data);
  }

  /// POST /payments/initiate
  /// Body: { transaction_ref, order_id }
  /// Returns: { payment_url, tx_ref }
  Future<PaymentInitResult> initiatePayment({
    required String transactionRef,
    required String orderId,
  }) async {
    final data = await _post('/payments/initiate', {
      'transaction_ref': transactionRef,
      'order_id': orderId,
    });
    return PaymentInitResult.fromJson(data);
  }

  /// GET /orders
  /// Response envelope uses "data" key (not "orders")
  Future<List<PickupOrder>> getOrders() async {
    final data = await _get('/orders');
    return (data['data'] as List) // ← was data['orders']
        .map((e) => PickupOrder.fromJson(e))
        .toList();
  }

  /// GET /orders/:id
  Future<PickupOrder> getOrder(String orderId) async {
    final data = await _get('/orders/$orderId');
    return PickupOrder.fromJson(data['order']);
  }

  /// POST /orders/:id/cancel
  Future<void> cancelOrder(String orderId) async {
    await _post('/orders/$orderId/cancel', {});
  }

  // ─── PAYMENT ──────────────────────────────────────────────────────────────

  /// POST /payments/verify
  /// Body: { transaction_ref, order_id }
  /// Called after Flutterwave callback to verify payment server-side
  Future<PaymentVerificationResult> verifyPayment({
    required String transactionRef,
    required String orderId,
  }) async {
    final data = await _post('/payments/verify', {
      'transaction_ref': transactionRef,
      'order_id': orderId,
    });
    return PaymentVerificationResult.fromJson(data);
  }

  // ─── WALLET ───────────────────────────────────────────────────────────────

  /// GET /wallet/balance
  Future<double> getWalletBalance() async {
    final data = await _get('/wallet/balance');
    return (data['balance'] as num).toDouble();
  }

  /// POST /wallet/topup
  /// Body: { amount }
  /// Returns: { payment_link } — Flutterwave link to fund wallet
  Future<String> initiateWalletTopup(double amount) async {
    final data = await _post('/wallet/topup', {'amount': amount});
    return data['payment_link'] as String;
  }

  /// POST /wallet/topup/verify
  /// Body: { transaction_ref }
  Future<double> verifyWalletTopup(String transactionRef) async {
    final data = await _post(
        '/wallet/topup/verify', {'transaction_ref': transactionRef});
    return (data['new_balance'] as num).toDouble();
  }

  /// GET /wallet/transactions
  Future<List<WalletTransaction>> getWalletTransactions() async {
    final data = await _get('/wallet/transactions');
    return (data['transactions'] as List)
        .map((e) => WalletTransaction.fromJson(e))
        .toList();
  }
}

// ─── Result models ────────────────────────────────────────────────────────────

class AuthResult {
  final AppUser user;
  final String token;

  AuthResult({required this.user, required this.token});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: AppUser.fromJson(json['user']),
        token: json['token'],
      );
}

class CreateOrderResult {
  final PickupOrder order;
  final String? paymentLink; // null when paying via wallet

  CreateOrderResult({required this.order, this.paymentLink});

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) =>
      CreateOrderResult(
        order: PickupOrder.fromJson(json['order']),
        paymentLink: json['payment_link'],
      );
}

class PaymentVerificationResult {
  final bool success;
  final String message;
  final PickupOrder? order;

  PaymentVerificationResult(
      {required this.success, required this.message, this.order});

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) =>
      PaymentVerificationResult(
        success: json['success'],
        message: json['message'],
        order:
            json['order'] != null ? PickupOrder.fromJson(json['order']) : null,
      );
}

class PaymentInitResult {
  final String paymentUrl;
  final String txRef;

  PaymentInitResult({required this.paymentUrl, required this.txRef});

  factory PaymentInitResult.fromJson(Map<String, dynamic> json) =>
      PaymentInitResult(
        paymentUrl: json['payment_url'].toString(),
        txRef: json['tx_ref'].toString(),
      );
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
