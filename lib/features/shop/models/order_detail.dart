import 'order_item.dart';

class OrderDetail {
  final String id;
  final String orderNumber;
  final String status;
  final String fulfillmentType;
  final String paymentStatus;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String? deliveryAddress;
  final List<OrderItem> items;
  final DateTime? createdAt;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.fulfillmentType,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.items,
    required this.createdAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return OrderDetail(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      fulfillmentType: json['fulfillment_type'] as String? ?? 'pickup',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['delivery_address'] as String?,
      items: items,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
