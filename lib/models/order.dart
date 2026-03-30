enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  washing,
  readyForDelivery,
  delivered,
  cancelled,
}

enum PaymentMethod { card, bankTransfer, wallet }

enum PaymentStatus { pending, success, failed }

class PickupOrder {
  final String id;
  final String userId;
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
        id: json['id'],
        userId: json['user_id'],
        zoneId: json['zone_id'],
        zoneName: json['zone_name'],
        address: json['address'],
        items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
        scheduledPickupDate: DateTime.parse(json['scheduled_pickup_date']),
        scheduledPickupTime: json['scheduled_pickup_time'],
        subtotal: (json['subtotal'] as num).toDouble(),
        deliveryFee: (json['delivery_fee'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        paymentMethod: PaymentMethod.values.byName(json['payment_method']),
        paymentStatus: PaymentStatus.values.byName(json['payment_status']),
        status: OrderStatus.values.byName(json['status']),
        flutterwaveRef: json['flutterwave_ref'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

class OrderItem {
  final String serviceId;
  final String serviceName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.serviceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        serviceId: json['service_id'],
        serviceName: json['service_name'],
        quantity: json['quantity'],
        unitPrice: (json['unit_price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'service_name': serviceName,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class WalletTransaction {
  final String id;
  final String userId;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final String? reference;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.reference,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'],
        userId: json['user_id'],
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        description: json['description'],
        reference: json['reference'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
