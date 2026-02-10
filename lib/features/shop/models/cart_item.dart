class CartItem {
  final String productId;
  final String name;
  final double price;
  final String unit;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.imageUrl,
  });

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      unit: unit,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }
}
