import 'dart:async';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final StreamController<void> _orderUpdateController = StreamController<void>.broadcast();

  Stream<void> get orderUpdateStream => _orderUpdateController.stream;

  void notifyOrderUpdated() {
    _orderUpdateController.sink.add(null);
  }

  void dispose() {
    _orderUpdateController.close();
  }
}