class RepairShop {
  final String id;
  final String name;
  final String description;
  final String address;
  final String area;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final Map<String, String> hours;
  final List<String> closingDays;
  final double latitude;
  final double longitude;
  final int durationMinutes;
  final bool requiresPurchase;
  final List<String> photos;
  final String priceRange;
  final Map<String, bool> features;

  RepairShop({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.area,
    required this.categories,
    required this.rating,
    this.reviewCount = 0,
    this.amenities = const [],
    required this.hours,
    this.closingDays = const [],
    required this.latitude,
    required this.longitude,
    this.durationMinutes = 0,
    this.requiresPurchase = false,
    this.photos = const [],
    this.priceRange = '₿',
    this.features = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'area': area,
      'categories': categories,
      'rating': rating,
      'reviewCount': reviewCount,
      'amenities': amenities,
      'hours': hours,
      'closingDays': closingDays,
      'latitude': latitude,
      'longitude': longitude,
      'durationMinutes': durationMinutes,
      'requiresPurchase': requiresPurchase,
      'photos': photos,
      'priceRange': priceRange,
      'features': features,
    };
  }
}
