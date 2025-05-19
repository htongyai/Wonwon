import '../models/repair_shop.dart';

class MockDataService {
  // Singleton pattern
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock shops
  List<RepairShop> getMockShops() {
    return [
      RepairShop(
        id: '1',
        name: 'Electronics Fix-It Shop',
        description: 'Expert repair services for all your electronics',
        address: '123 Main Street',
        area: 'Downtown',
        categories: ['electronics', 'smartphone'],
        rating: 4.8,
        reviewCount: 42,
        amenities: ['Waiting Area', 'Free Diagnostics', 'Warranty Service'],
        hours: {'weekday': '09:00 - 18:00', 'weekend': '10:00 - 16:00'},
        closingDays: ['sunday'],
        latitude: 13.7041,
        longitude: 100.5999,
        durationMinutes: 120,
        requiresPurchase: false,
        photos: [
          'https://images.unsplash.com/photo-1588945032743-a5e9558d5a04?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        priceRange: '₿₿',
        features: {'pickup': true, 'delivery': false},
      ),
      RepairShop(
        id: '2',
        name: 'Tech Doctors',
        description: 'Computer, laptop, and smartphone repair services',
        address: '456 Oak Avenue',
        area: 'Midtown',
        categories: ['computer', 'smartphone', 'tablet'],
        rating: 4.5,
        reviewCount: 36,
        amenities: ['Waiting Area', 'Free Diagnostics', 'Data Recovery'],
        hours: {'weekday': '08:00 - 19:00', 'weekend': '10:00 - 17:00'},
        closingDays: [],
        latitude: 13.7225,
        longitude: 100.5809,
        durationMinutes: 60,
        requiresPurchase: false,
        photos: [
          'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        priceRange: '₿₿',
        features: {'pickup': false, 'delivery': true},
      ),
      RepairShop(
        id: '3',
        name: 'Auto Repair Pro',
        description: 'Complete auto repair and maintenance services',
        address: '789 Mechanics Lane',
        area: 'Industrial District',
        categories: ['auto', 'mechanical'],
        rating: 4.7,
        reviewCount: 58,
        amenities: ['Waiting Room', 'Free Inspection', 'Warranty Service'],
        hours: {'weekday': '07:00 - 18:00', 'weekend': '08:00 - 15:00'},
        closingDays: ['sunday'],
        latitude: 13.7372,
        longitude: 100.5601,
        durationMinutes: 180,
        requiresPurchase: false,
        photos: [
          'https://images.unsplash.com/photo-1530046339915-88659155b628?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        priceRange: '₿₿₿',
        features: {'pickup': true, 'delivery': true},
      ),
      RepairShop(
        id: '4',
        name: 'Appliance Experts',
        description: 'Repair services for all major home appliances',
        address: '101 Household Drive',
        area: 'Suburban Center',
        categories: ['appliance', 'home'],
        rating: 4.4,
        reviewCount: 31,
        amenities: ['Same-day Service', 'Parts Warranty', '24/7 Support'],
        hours: {'weekday': '08:00 - 17:00', 'weekend': '09:00 - 14:00'},
        closingDays: ['sunday'],
        latitude: 13.7262,
        longitude: 100.5272,
        durationMinutes: 120,
        requiresPurchase: false,
        photos: [
          'https://images.unsplash.com/photo-1581092921461-7a0e8da4f086?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        priceRange: '₿₿',
        features: {'pickup': false, 'delivery': false},
      ),
      RepairShop(
        id: '5',
        name: 'Bicycle Repair Station',
        description: 'Expert bicycle repair and maintenance',
        address: '555 Cycling Way',
        area: 'City Park',
        categories: ['bicycle', 'sports'],
        rating: 4.9,
        reviewCount: 47,
        amenities: ['Test Ride', 'Quick Tune-ups', 'Parts Shop'],
        hours: {'weekday': '09:00 - 18:00', 'weekend': '08:00 - 19:00'},
        closingDays: ['monday'],
        latitude: 13.7315,
        longitude: 100.5408,
        durationMinutes: 60,
        requiresPurchase: false,
        photos: [
          'https://images.unsplash.com/photo-1529236183275-4fdcf2bc987e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1489&q=80',
        ],
        priceRange: '₿',
        features: {'pickup': false, 'delivery': false},
      ),
    ];
  }
}
