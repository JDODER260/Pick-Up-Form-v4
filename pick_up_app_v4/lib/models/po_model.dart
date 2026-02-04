class PickupOrder {
  final String id;
  final String description;
  final String company;
  final String route;
  final int quantity;
  final DateTime pickupDate;
  final String driverId;
  final bool uploaded;
  final Map<String, dynamic>? bladeDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PickupOrder({
    required this.id,
    required this.description,
    required this.company,
    required this.route,
    required this.quantity,
    required this.pickupDate,
    required this.driverId,
    this.uploaded = false,
    this.bladeDetails,
    required this.createdAt,
    this.updatedAt,
  });

  factory PickupOrder.fromJson(Map<String, dynamic> json) {
    return PickupOrder(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      company: json['company'] ?? '',
      route: json['route'] ?? '',
      quantity: json['quantity'] ?? 0,
      pickupDate: DateTime.parse(json['pickupDate'] ?? DateTime.now().toIso8601String()),
      driverId: json['driverId'] ?? '',
      uploaded: json['uploaded'] ?? false,
      bladeDetails: json['bladeDetails'] ?? {},
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'company': company,
      'route': route,
      'quantity': quantity,
      'pickupDate': pickupDate.toIso8601String(),
      'driverId': driverId,
      'uploaded': uploaded,
      'bladeDetails': bladeDetails ?? {},
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ✅ copyWith method
  PickupOrder copyWith({
    String? id,
    String? description,
    String? company,
    String? route,
    int? quantity,
    DateTime? pickupDate,
    String? driverId,
    bool? uploaded,
    Map<String, dynamic>? bladeDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PickupOrder(
      id: id ?? this.id,
      description: description ?? this.description,
      company: company ?? this.company,
      route: route ?? this.route,
      quantity: quantity ?? this.quantity,
      pickupDate: pickupDate ?? this.pickupDate,
      driverId: driverId ?? this.driverId,
      uploaded: uploaded ?? this.uploaded,
      bladeDetails: bladeDetails ?? this.bladeDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
