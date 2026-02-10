class OrderItem {
  final String id;
  final String productName;
  final double priceAtPurchase;
  final int quantity;
  final String unit;

  const OrderItem({
    required this.id,
    required this.productName,
    required this.priceAtPurchase,
    required this.quantity,
    required this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      productName: json['product_name'] as String? ?? '',
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? '',
    );
  }
}
