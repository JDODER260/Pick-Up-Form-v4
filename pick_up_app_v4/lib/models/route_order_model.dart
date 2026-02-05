class RouteStop {
  final String name;
  final String latCoords;
  final String longCoords;
  final String sortNum;
  final bool show;

  RouteStop({
    required this.name,
    required this.latCoords,
    required this.longCoords,
    required this.sortNum,
    this.show = true,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      name: json['name'] ?? '',
      latCoords: json['lat_coords'] ?? '',
      longCoords: json['long_coords'] ?? '',
      sortNum: json['sort_num']?.toString() ?? '',
      show: json['show'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat_coords': latCoords,
      'long_coords': longCoords,
      'sort_num': sortNum,
      'show': show,
    };
  }

  String get displayName {
    return '${sortNum.isNotEmpty ? '$sortNum. ' : ''}$name';
  }
}