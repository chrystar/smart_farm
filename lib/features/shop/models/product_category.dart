class ProductCategory {
  final String id;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.isActive,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
