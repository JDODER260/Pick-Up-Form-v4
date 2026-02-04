import 'package:intl/intl.dart';

class DeliveryPO {
  final String poNumber;
  final String description;
  final int quantity;
  final DateTime pickupDate;
  final String expectedDelivery;
  final Map<String, dynamic> bladeDetails;

  DeliveryPO({
    required this.poNumber,
    required this.description,
    required this.quantity,
    required this.pickupDate,
    required this.expectedDelivery,
    required this.bladeDetails,
  });

  factory DeliveryPO.fromJson(Map<String, dynamic> json) {
    // po_number might be int or string
    String poNum = '';
    final poRaw = json['po_number'];
    if (poRaw is int) {
      poNum = poRaw.toString();
    } else if (poRaw is String) {
      poNum = poRaw;
    }

    // quantity may be a string or number
    int qty = 0;
    final qRaw = json['quantity'];
    if (qRaw is int) {
      qty = qRaw;
    } else if (qRaw is String) {
      qty = int.tryParse(qRaw) ?? 0;
    }

    // Handle date parsing - support multiple formats
    DateTime pickup;
    try {
      final dateStr = json['pickup_date']?.toString();
      if (dateStr == null || dateStr.isEmpty) {
        pickup = DateTime.now();
      } else {
        // Try ISO format first (e.g., "2026-01-28T14:26:24.065406")
        if (dateStr.contains('T') && dateStr.contains('-')) {
          pickup = DateTime.parse(dateStr);
        }
        // Try "MM/dd/yyyy" format (e.g., "12/23/2025")
        else if (dateStr.contains('/')) {
          pickup = DateFormat('MM/dd/yyyy').parse(dateStr);
        }
        // Try other common formats
        else if (dateStr.contains('-')) {
          // Try "yyyy-MM-dd" format
          try {
            pickup = DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (e) {
            pickup = DateTime.now();
          }
        } else {
          pickup = DateTime.now();
        }
      }
    } catch (e) {
      print('Error parsing date: ${json['pickup_date']}, error: $e');
      pickup = DateTime.now();
    }

    return DeliveryPO(
      poNumber: poNum,
      description: json['description']?.toString() ?? '',
      quantity: qty,
      pickupDate: pickup,
      expectedDelivery: json['expected_delivery']?.toString() ?? 'N/A',
      bladeDetails: (json['blade_details'] is Map)
          ? Map<String, dynamic>.from(json['blade_details'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_number': poNumber,
      'description': description,
      'quantity': quantity,
      'pickup_date': DateFormat('MM/dd/yyyy').format(pickupDate),
      'expected_delivery': expectedDelivery,
      'blade_details': bladeDetails,
    };
  }
}

class DeliveryCompany {
  final String companyName;
  final List<DeliveryPO> poList;

  DeliveryCompany({
    required this.companyName,
    required this.poList,
  });

  factory DeliveryCompany.fromJson(Map<String, dynamic> json) {
    final poList = <DeliveryPO>[];
    final companyName = json['company_name']?.toString() ?? '';

    if (json['po_list'] is List) {
      for (var item in json['po_list']) {
        if (item is Map<String, dynamic>) {
          poList.add(DeliveryPO.fromJson(item));
        }
      }
    }

    return DeliveryCompany(
      companyName: companyName,
      poList: poList,
    );
  }

  // New factory for company name -> list of POs
  factory DeliveryCompany.fromMapEntry(String companyName, List<dynamic> poListJson) {
    final poList = <DeliveryPO>[];

    for (var item in poListJson) {
      if (item is Map<String, dynamic>) {
        poList.add(DeliveryPO.fromJson(item));
      }
    }

    return DeliveryCompany(
      companyName: companyName,
      poList: poList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'po_list': poList.map((po) => po.toJson()).toList(),
    };
  }
}

class DeliveryData {
  final String route;
  final List<DeliveryCompany> companies;

  DeliveryData({
    required this.route,
    required this.companies,
  });

  factory DeliveryData.fromJson(Map<String, dynamic> json) {
    final route = json['route']?.toString() ?? '';
    final companies = <DeliveryCompany>[];

    // Check if we have the structure from your example API
    if (json.containsKey('success') && json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        // data is like: {"JN Pallet": [{...}, {...}]}
        data.forEach((companyName, poListJson) {
          if (poListJson is List) {
            companies.add(DeliveryCompany.fromMapEntry(companyName, poListJson));
          }
        });
      }
      return DeliveryData(route: route, companies: companies);
    }

    // Otherwise try other structures
    if (json['companies'] is List) {
      for (var item in json['companies']) {
        if (item is Map<String, dynamic>) {
          companies.add(DeliveryCompany.fromJson(item));
        }
      }
    }

    // Last resort: assume keys are company names
    json.forEach((key, value) {
      if (value is List && key != 'route') {
        companies.add(DeliveryCompany.fromMapEntry(key, value));
      }
    });

    return DeliveryData(route: route, companies: companies);
  }

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'companies': companies.map((company) => company.toJson()).toList(),
    };
  }
}