import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

/// Manages order list state reactively so HomeScreen, OrdersScreen,
/// and OrderDetailScreen all stay in sync without re-fetching separately.
class OrderProvider extends ChangeNotifier {
  final ApiService _api;

  List<PickupOrder> _orders = [];
  bool _loading = false;
  String? _error;

  OrderProvider(this._api);

  List<PickupOrder> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  List<PickupOrder> get activeOrders => _orders
      .where((o) => ![OrderStatus.delivered, OrderStatus.cancelled].contains(o.status))
      .toList();

  List<PickupOrder> get pastOrders => _orders
      .where((o) => [OrderStatus.delivered, OrderStatus.cancelled].contains(o.status))
      .toList();

  PickupOrder? get latestActiveOrder => activeOrders.isNotEmpty ? activeOrders.first : null;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _api.getOrders();
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Failed to load orders';
      _loading = false;
      notifyListeners();
    }
  }

  Future<PickupOrder?> refreshOrder(String orderId) async {
    try {
      final updated = await _api.getOrder(orderId);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (_) {
      return null;
    }
  }

  void addOrder(PickupOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void removeOrder(String orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }
}
