class Product {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String unit;
  final List<String> images;
  final bool isActive;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.unit,
    required this.images,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    return Product(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? '',
      images: imagesRaw is List
          ? imagesRaw.map((e) => e.toString()).toList()
          : const [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
