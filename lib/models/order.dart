enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  washing,
  readyForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { card, wallet }

enum PaymentStatus { pending, success, failed }

// ─── SERVICE (from GET /services) ─────────────────────────────────────────────

class LaundryService {
  final int id;
  final String name;
  final String emoji;
  final double price;

  const LaundryService({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
  });

  factory LaundryService.fromJson(Map<String, dynamic> json) => LaundryService(
        id: json['id'] as int,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        price: double.parse(json['price'].toString()),
      );
}

// ─── ORDER ────────────────────────────────────────────────────────────────────

class PickupOrder {
  final String id;
  final int userId;
  final String zoneId;
  final String zoneName;
  final String address;
  final List<OrderItem> items;
  final DateTime scheduledPickupDate;
  final String scheduledPickupTime;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final String? flutterwaveRef;
  final String? notes;
  final DateTime createdAt;

  const PickupOrder({
    required this.id,
    required this.userId,
    required this.zoneId,
    required this.zoneName,
    required this.address,
    required this.items,
    required this.scheduledPickupDate,
    required this.scheduledPickupTime,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.status = OrderStatus.pending,
    this.flutterwaveRef,
    this.notes,
    required this.createdAt,
  });

  factory PickupOrder.fromJson(Map<String, dynamic> json) => PickupOrder(
        id: json['id'].toString(),
        userId: json['user_id'] is int
            ? json['user_id']
            : int.parse(json['user_id'].toString()),
        zoneId: json['zone_id'].toString(),
        zoneName: json['zone_name'].toString(),
        address: json['address'].toString(),
        items:
            (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
        scheduledPickupDate: DateTime.parse(json['scheduled_pickup_date']),
        scheduledPickupTime: json['scheduled_pickup_time'].toString(),
        subtotal: (json['subtotal'] as num).toDouble(),
        deliveryFee: (json['delivery_fee'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'] == 'wallet'
            ? PaymentMethod.wallet
            : PaymentMethod.card,
        paymentStatus: _parsePaymentStatus(json['payment_status']),
        status: _parseOrderStatus(json['status']),
        flutterwaveRef: json['flutterwave_ref']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: DateTime.parse(json['created_at']),
      );

  static PaymentStatus _parsePaymentStatus(dynamic v) {
    switch (v?.toString()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  static OrderStatus _parseOrderStatus(dynamic v) {
    switch (v?.toString()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'washing':
        return OrderStatus.washing;
      case 'ready_for_delivery':
        return OrderStatus.readyForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

// ─── ORDER ITEM ───────────────────────────────────────────────────────────────

class OrderItem {
  final String serviceId; // ← String to handle both int IDs and legacy slugs
  final String serviceName;
  final String? emoji;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.serviceId,
    required this.serviceName,
    this.emoji,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        serviceId: json['service_id'].toString(), // safe for int or slug string
        serviceName: json['service_name'].toString(),
        emoji: json['emoji']?.toString(),
        quantity: json['quantity'] as int,
        unitPrice: (json['unit_price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'quantity': quantity,
      };
}

// ─── WALLET TRANSACTION ───────────────────────────────────────────────────────

class WalletTransaction {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String description;
  final String status;
  final String? reference;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.reference,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        type: json['type'].toString(),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'].toString(),
        status: json['status'].toString(),
        reference: json['reference']?.toString(),
        createdAt: DateTime.parse(json['created_at']),
      );
}
