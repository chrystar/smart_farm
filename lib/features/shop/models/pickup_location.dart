class PickupLocation {
  final String id;
  final String locationName;
  final String address;
  final String? state;
  final String? phone;
  final bool isActive;

  const PickupLocation({
    required this.id,
    required this.locationName,
    required this.address,
    required this.state,
    required this.phone,
    required this.isActive,
  });

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      id: json['id'] as String,
      locationName: json['location_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      state: json['state'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
