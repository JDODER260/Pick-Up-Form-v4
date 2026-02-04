class Company {
  final String name;
  final List<String> frequentBlades;

  Company({
    required this.name,
    required this.frequentBlades,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] ?? '',
      frequentBlades: List<String>.from(json['frequentBlades'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'frequentBlades': frequentBlades,
    };
  }
}

class RouteCompanies {
  final String routeName;
  final Map<String, Company> companies;

  RouteCompanies({
    required this.routeName,
    required this.companies,
  });

  factory RouteCompanies.fromJson(String route_name, Map<String, dynamic> json) {
    final companies = <String, Company>{};

    json.forEach((key, value) {
      companies[key] = Company.fromJson(value as Map<String, dynamic>);
    });

    return RouteCompanies(
      routeName: route_name,
      companies: companies,
    );
  }


  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    companies.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
}