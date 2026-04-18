import 'order.dart';

class PayOrderResult {
  final PickupOrder order;
  final String? paymentLink;

  PayOrderResult({
    required this.order,
    this.paymentLink,
  });

  factory PayOrderResult.fromJson(Map<String, dynamic> json) {
    return PayOrderResult(
      order: PickupOrder.fromJson(json['order']),
      paymentLink: json['payment_link'],
    );
  }
}
