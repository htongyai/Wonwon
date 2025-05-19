import '../models/repair_shop.dart';

class MockShopsExtended {
  static List<RepairShop> getAdditionalShops() {
    return [
      // Additional clothing repair shops
      RepairShop(
        id: 'shop8',
        name: 'Stitch Perfect',
        description:
            'Precise alterations and repairs for all types of clothing. Fast turnaround and expert craftsmanship.',
        address: '321 Fabric Lane, Fashion District',
        area: 'Fashion District',
        categories: ['clothing'],
        rating: 4.6,
        reviewCount: 87,
        hours: {
          'Monday': '9:00 AM - 6:00 PM',
          'Tuesday': '9:00 AM - 6:00 PM',
          'Wednesday': '9:00 AM - 6:00 PM',
          'Thursday': '9:00 AM - 6:00 PM',
          'Friday': '9:00 AM - 6:00 PM',
          'Saturday': '10:00 AM - 4:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7510,
        longitude: 100.5020,
        photos: [
          'https://images.unsplash.com/photo-1584992236310-6aded424aeb4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop9',
        name: 'The Tailoring Studio',
        description:
            'Luxury clothing repair and alterations. Specialized in formal wear and designer garments.',
        address: '455 Elite Street, Uptown',
        area: 'Uptown',
        categories: ['clothing'],
        rating: 4.8,
        reviewCount: 134,
        hours: {
          'Monday': '10:00 AM - 7:00 PM',
          'Tuesday': '10:00 AM - 7:00 PM',
          'Wednesday': '10:00 AM - 7:00 PM',
          'Thursday': '10:00 AM - 7:00 PM',
          'Friday': '10:00 AM - 7:00 PM',
          'Saturday': '11:00 AM - 5:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7350,
        longitude: 100.5150,
        photos: [
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),

      // Additional footwear repair shops
      RepairShop(
        id: 'shop10',
        name: 'The Cobbler Shop',
        description:
            'Traditional cobbler services with modern techniques. Specializing in leather shoes and boots repair.',
        address: '222 Boot Alley, Old Town',
        area: 'Old Town',
        categories: ['footwear'],
        rating: 4.7,
        reviewCount: 112,
        hours: {
          'Monday': '8:00 AM - 5:00 PM',
          'Tuesday': '8:00 AM - 5:00 PM',
          'Wednesday': '8:00 AM - 5:00 PM',
          'Thursday': '8:00 AM - 5:00 PM',
          'Friday': '8:00 AM - 5:00 PM',
          'Saturday': '9:00 AM - 3:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7240,
        longitude: 100.5280,
        photos: [
          'https://images.unsplash.com/photo-1565814329452-e1efa11c5b89?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop11',
        name: 'Sneaker Clinic',
        description:
            'Specialized in athletic and designer sneaker repair, cleaning, and restoration.',
        address: '789 Urban Street, Modern District',
        area: 'Modern District',
        categories: ['footwear'],
        rating: 4.9,
        reviewCount: 156,
        hours: {
          'Monday': '10:00 AM - 8:00 PM',
          'Tuesday': '10:00 AM - 8:00 PM',
          'Wednesday': '10:00 AM - 8:00 PM',
          'Thursday': '10:00 AM - 8:00 PM',
          'Friday': '10:00 AM - 8:00 PM',
          'Saturday': '11:00 AM - 6:00 PM',
          'Sunday': '12:00 PM - 5:00 PM',
        },
        closingDays: [],
        latitude: 13.7430,
        longitude: 100.5350,
        photos: [
          'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),

      // Additional watch repair shops
      RepairShop(
        id: 'shop12',
        name: 'Precision Time',
        description:
            'Expert watch and clock repair services. Battery replacements, band adjustments, and movement repairs.',
        address: '345 Timepiece Street, Clockwork District',
        area: 'Clockwork District',
        categories: ['watch'],
        rating: 4.8,
        reviewCount: 98,
        hours: {
          'Monday': '9:00 AM - 6:00 PM',
          'Tuesday': '9:00 AM - 6:00 PM',
          'Wednesday': '9:00 AM - 6:00 PM',
          'Thursday': '9:00 AM - 6:00 PM',
          'Friday': '9:00 AM - 6:00 PM',
          'Saturday': '10:00 AM - 4:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7320,
        longitude: 100.5230,
        photos: [
          'https://images.unsplash.com/photo-1619811087132-b49fb4446c97?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop13',
        name: 'Luxury Watch Specialists',
        description:
            'High-end watch repair and servicing for premium brands. Certified watchmakers with decades of experience.',
        address: '678 Luxury Avenue, Exclusive District',
        area: 'Exclusive District',
        categories: ['watch'],
        rating: 4.9,
        reviewCount: 76,
        hours: {
          'Monday': '10:00 AM - 5:00 PM',
          'Tuesday': '10:00 AM - 5:00 PM',
          'Wednesday': '10:00 AM - 5:00 PM',
          'Thursday': '10:00 AM - 5:00 PM',
          'Friday': '10:00 AM - 5:00 PM',
          'Saturday': 'By appointment only',
          'Sunday': 'Closed',
        },
        closingDays: ['Saturday', 'Sunday'],
        latitude: 13.7380,
        longitude: 100.5410,
        photos: [
          'https://images.unsplash.com/photo-1526045612212-70caf35c14df?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),

      // Additional bag repair shops
      RepairShop(
        id: 'shop14',
        name: 'Baggage Revival',
        description:
            'Full-service bag and luggage repair. Fixing zippers, handles, and structural damage for all types of bags.',
        address: '999 Luggage Lane, Commerce District',
        area: 'Commerce District',
        categories: ['bag'],
        rating: 4.5,
        reviewCount: 84,
        hours: {
          'Monday': '9:00 AM - 6:00 PM',
          'Tuesday': '9:00 AM - 6:00 PM',
          'Wednesday': '9:00 AM - 6:00 PM',
          'Thursday': '9:00 AM - 6:00 PM',
          'Friday': '9:00 AM - 6:00 PM',
          'Saturday': '10:00 AM - 5:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7190,
        longitude: 100.5120,
        photos: [
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop15',
        name: 'Leather Restoration Studio',
        description:
            'Specialized leather goods repair and restoration. Expert color matching and stitch work.',
        address: '444 Leather Street, Artisan Quarter',
        area: 'Artisan Quarter',
        categories: ['bag'],
        rating: 4.7,
        reviewCount: 92,
        hours: {
          'Monday': '10:00 AM - 6:00 PM',
          'Tuesday': '10:00 AM - 6:00 PM',
          'Wednesday': '10:00 AM - 6:00 PM',
          'Thursday': '10:00 AM - 6:00 PM',
          'Friday': '10:00 AM - 6:00 PM',
          'Saturday': '11:00 AM - 4:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7480,
        longitude: 100.5390,
        photos: [
          'https://images.unsplash.com/photo-1499933374294-4584851497cc?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
    ];
  }
}
