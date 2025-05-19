import 'package:google_maps_flutter/google_maps_flutter.dart';

class RepairShop {
  final String id;
  final String name;
  final LatLng location;
  final double rating;
  final List<String> categories;
  final String address;
  final String imageUrl;
  final String phone;
  final Map<String, String> openingHours;
  final String description;
  final int reviewCount;

  RepairShop({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.categories,
    this.address = '',
    this.imageUrl = '',
    this.phone = '',
    this.openingHours = const {},
    this.description = '',
    this.reviewCount = 0,
  });
}

class MockShops {
  static final List<RepairShop> shops = [
    RepairShop(
      id: 'shop-001',
      name: 'Central Bangkok Repair',
      location: const LatLng(13.7466, 100.5338),
      rating: 4.5,
      categories: ['Electronics', 'Appliances'],
      address: '123 Silom Road, Bangkok',
      phone: '+66 2 123 4567',
      description:
          'Specializing in electronic device repair with quick turnaround times.',
      openingHours: {
        'Monday': '9:00 - 18:00',
        'Tuesday': '9:00 - 18:00',
        'Wednesday': '9:00 - 18:00',
        'Thursday': '9:00 - 18:00',
        'Friday': '9:00 - 18:00',
        'Saturday': '10:00 - 16:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1588702547919-26089e690ecc?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 124,
    ),
    RepairShop(
      id: 'shop-002',
      name: 'Siam Tech Repairs',
      location: const LatLng(13.7462, 100.5347),
      rating: 4.8,
      categories: ['Electronics', 'Phones'],
      address: '45 Siam Square, Bangkok',
      phone: '+66 2 456 7890',
      description: 'Expert phone and tablet repair service with genuine parts.',
      openingHours: {
        'Monday': '10:00 - 20:00',
        'Tuesday': '10:00 - 20:00',
        'Wednesday': '10:00 - 20:00',
        'Thursday': '10:00 - 20:00',
        'Friday': '10:00 - 20:00',
        'Saturday': '10:00 - 20:00',
        'Sunday': '12:00 - 18:00',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1579389083078-4e7018379f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 208,
    ),
    RepairShop(
      id: 'shop-003',
      name: 'Bangkok Watch Repair',
      location: const LatLng(13.7556, 100.5021),
      rating: 4.2,
      categories: ['Watches', 'Jewelry'],
      address: '78/3 Sukhumvit Road, Bangkok',
      phone: '+66 2 789 0123',
      description:
          'Luxury watch repair and servicing by certified horologists.',
      openingHours: {
        'Monday': '9:30 - 17:30',
        'Tuesday': '9:30 - 17:30',
        'Wednesday': '9:30 - 17:30',
        'Thursday': '9:30 - 17:30',
        'Friday': '9:30 - 17:30',
        'Saturday': '9:30 - 15:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1612099993322-3d191db84f38?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 87,
    ),
    RepairShop(
      id: 'shop-004',
      name: 'Sukhumvit Shoe Fix',
      location: const LatLng(13.7380, 100.5608),
      rating: 4.0,
      categories: ['Footwear'],
      address: '120 Sukhumvit 22, Bangkok',
      phone: '+66 2 012 3456',
      description: 'Specialized in leather shoe repair and restoration.',
      openingHours: {
        'Monday': '8:00 - 17:00',
        'Tuesday': '8:00 - 17:00',
        'Wednesday': '8:00 - 17:00',
        'Thursday': '8:00 - 17:00',
        'Friday': '8:00 - 17:00',
        'Saturday': '9:00 - 14:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1545454675-3531b543be5d?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 63,
    ),
    RepairShop(
      id: 'shop-005',
      name: 'Master Tailor Bangkok',
      location: const LatLng(13.7310, 100.5690),
      rating: 4.7,
      categories: ['Clothing'],
      address: '55 Thonglor, Bangkok',
      phone: '+66 2 345 6789',
      description:
          'Premium clothing alterations and repairs by experienced tailors.',
      openingHours: {
        'Monday': '9:00 - 19:00',
        'Tuesday': '9:00 - 19:00',
        'Wednesday': '9:00 - 19:00',
        'Thursday': '9:00 - 19:00',
        'Friday': '9:00 - 19:00',
        'Saturday': '10:00 - 18:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 152,
    ),
    RepairShop(
      id: 'shop-006',
      name: 'Bag Doctor',
      location: const LatLng(13.7230, 100.5120),
      rating: 4.9,
      categories: ['Bags'],
      address: '90/2 Sathorn Road, Bangkok',
      phone: '+66 2 678 9012',
      description: 'Specializing in designer bag repair and restoration.',
      openingHours: {
        'Monday': '10:00 - 18:00',
        'Tuesday': '10:00 - 18:00',
        'Wednesday': '10:00 - 18:00',
        'Thursday': '10:00 - 18:00',
        'Friday': '10:00 - 18:00',
        'Saturday': '11:00 - 16:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1564304222252-644a74d90586?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 97,
    ),
    RepairShop(
      id: 'shop-007',
      name: 'Royal Thai Jewelry Repair',
      location: const LatLng(13.7510, 100.4920),
      rating: 4.6,
      categories: ['Jewelry'],
      address: '22 Rajdamri Road, Bangkok',
      phone: '+66 2 890 1234',
      description: 'Trusted jewelers offering repair and restoration services.',
      openingHours: {
        'Monday': '10:00 - 19:00',
        'Tuesday': '10:00 - 19:00',
        'Wednesday': '10:00 - 19:00',
        'Thursday': '10:00 - 19:00',
        'Friday': '10:00 - 19:00',
        'Saturday': '10:00 - 19:00',
        'Sunday': '12:00 - 18:00',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 176,
    ),
    RepairShop(
      id: 'shop-008',
      name: 'Bangkok Home Appliance Fix',
      location: const LatLng(13.7670, 100.5420),
      rating: 4.3,
      categories: ['Appliances'],
      address: '150 Ratchadapisek Road, Bangkok',
      phone: '+66 2 901 2345',
      description: 'Fast and reliable home appliance repair service.',
      openingHours: {
        'Monday': '8:30 - 17:30',
        'Tuesday': '8:30 - 17:30',
        'Wednesday': '8:30 - 17:30',
        'Thursday': '8:30 - 17:30',
        'Friday': '8:30 - 17:30',
        'Saturday': '9:00 - 15:00',
        'Sunday': 'Closed',
      },
      imageUrl:
          'https://images.unsplash.com/photo-1581092921461-7d65ca45c075?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80',
      reviewCount: 83,
    ),
  ];
}
