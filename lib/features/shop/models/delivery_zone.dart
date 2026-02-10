class DeliveryZone {
  final String id;
  final String stateName;
  final double deliveryFee;
  final String? estimatedDays;
  final bool isActive;

  const DeliveryZone({
    required this.id,
    required this.stateName,
    required this.deliveryFee,
    required this.estimatedDays,
    required this.isActive,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'] as String,
      stateName: json['state_name'] as String? ?? '',
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      estimatedDays: json['estimated_days'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
