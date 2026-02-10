class OrderSummary {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String fulfillmentType;
  final String paymentStatus;
  final DateTime? createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.fulfillmentType,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      fulfillmentType: json['fulfillment_type'] as String? ?? 'pickup',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
