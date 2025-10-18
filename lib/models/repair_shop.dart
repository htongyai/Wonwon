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
  final bool approved;
  final bool irregularHours;
  final Map<String, List<String>>
  subServices; // Map of category ID to list of sub-service IDs
  final DateTime? timestamp;
  final String? buildingNumber;
  final String? buildingName;
  final String? soi;
  final String? district;
  final String? province;
  final String? landmark;
  final String? lineId;
  final String? facebookPage;
  final String? otherContacts;
  final List<String>? paymentMethods;
  final bool? tryOnAreaAvailable;
  final String? notesOrConditions;
  final String? usualOpeningTime;
  final String? usualClosingTime;
  final String? instagramPage;
  final String? phoneNumber;
  final String? buildingFloor;

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
    this.approved = false,
    this.irregularHours = false,
    this.subServices = const {},
    this.timestamp,
    this.buildingNumber,
    this.buildingName,
    this.soi,
    this.district,
    this.province,
    this.landmark,
    this.lineId,
    this.facebookPage,
    this.otherContacts,
    this.paymentMethods,
    this.tryOnAreaAvailable,
    this.notesOrConditions,
    this.usualOpeningTime,
    this.usualClosingTime,
    this.instagramPage,
    this.phoneNumber,
    this.buildingFloor,
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
      'approved': approved,
      'irregularHours': irregularHours,
      'subServices': subServices,
      'timestamp': timestamp?.toIso8601String(),
      'buildingNumber': buildingNumber,
      'buildingName': buildingName,
      'buildingFloor': buildingFloor,
      'soi': soi,
      'district': district,
      'province': province,
      'landmark': landmark,
      'lineId': lineId,
      'facebookPage': facebookPage,
      'otherContacts': otherContacts,
      'paymentMethods': paymentMethods,
      'tryOnAreaAvailable': tryOnAreaAvailable,
      'notesOrConditions': notesOrConditions,
      'usualOpeningTime': usualOpeningTime,
      'usualClosingTime': usualClosingTime,
      'instagramPage': instagramPage,
      'phoneNumber': phoneNumber,
    };
  }

  factory RepairShop.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert dynamic list to List<String>
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Helper function to safely convert dynamic map to Map<String, String>
    Map<String, String> safeStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, String>.fromEntries(
          value.entries.map(
            (e) => MapEntry(e.key.toString(), e.value.toString()),
          ),
        );
      }
      return {};
    }

    // Helper function to safely convert dynamic map to Map<String, List<String>>
    Map<String, List<String>> safeSubServicesMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, List<String>>.fromEntries(
          value.entries.map(
            (e) => MapEntry(e.key.toString(), safeStringList(e.value)),
          ),
        );
      }
      return {};
    }

    // Helper function to safely convert dynamic map to Map<String, bool>
    Map<String, bool> safeBoolMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, bool>.fromEntries(
          value.entries.map(
            (e) =>
                MapEntry(e.key.toString(), e.value is bool ? e.value : false),
          ),
        );
      }
      return {};
    }

    return RepairShop(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      categories: safeStringList(map['categories']),
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 0.0,
      reviewCount:
          (map['reviewCount'] is num) ? (map['reviewCount'] as num).toInt() : 0,
      amenities: safeStringList(map['amenities']),
      hours: safeStringMap(map['hours']),
      closingDays: safeStringList(map['closingDays']),
      latitude:
          (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude:
          (map['longitude'] is num)
              ? (map['longitude'] as num).toDouble()
              : 0.0,
      durationMinutes:
          (map['durationMinutes'] is num)
              ? (map['durationMinutes'] as num).toInt()
              : 0,
      requiresPurchase:
          map['requiresPurchase'] is bool
              ? map['requiresPurchase'] as bool
              : false,
      photos: safeStringList(map['photos']),
      priceRange: map['priceRange']?.toString() ?? '₿',
      features: safeBoolMap(map['features']),
      approved: map['approved'] is bool ? map['approved'] as bool : false,
      irregularHours:
          map['irregularHours'] is bool ? map['irregularHours'] as bool : false,
      subServices: safeSubServicesMap(map['subServices']),
      timestamp:
          map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
      buildingNumber: map['buildingNumber'],
      buildingName: map['buildingName'],
      soi: map['soi'],
      district: map['district'],
      province: map['province'],
      landmark: map['landmark'],
      lineId: map['lineId'],
      facebookPage: map['facebookPage'],
      otherContacts: map['otherContacts'],
      paymentMethods:
          map['paymentMethods'] != null
              ? List<String>.from(map['paymentMethods'])
              : null,
      tryOnAreaAvailable: map['tryOnAreaAvailable'],
      notesOrConditions: map['notesOrConditions'],
      usualOpeningTime: map['usualOpeningTime'],
      usualClosingTime: map['usualClosingTime'],
      instagramPage: map['instagramPage'],
      phoneNumber: map['phoneNumber'],
      buildingFloor: map['buildingFloor'],
    );
  }
}
