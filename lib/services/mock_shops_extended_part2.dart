import '../models/repair_shop.dart';

class MockShopsExtendedPart2 {
  static List<RepairShop> getAdditionalShops() {
    return [
      // Additional electronics repair shops
      RepairShop(
        id: 'shop16',
        name: 'TechGenius Repair',
        description:
            'Expert repair services for smartphones, tablets, and laptops. Quick turnaround and quality parts.',
        address: '123 Tech Boulevard, Silicon District',
        area: 'Silicon District',
        categories: ['electronics'],
        rating: 4.8,
        reviewCount: 178,
        hours: {
          'Monday': '8:00 AM - 8:00 PM',
          'Tuesday': '8:00 AM - 8:00 PM',
          'Wednesday': '8:00 AM - 8:00 PM',
          'Thursday': '8:00 AM - 8:00 PM',
          'Friday': '8:00 AM - 8:00 PM',
          'Saturday': '9:00 AM - 6:00 PM',
          'Sunday': '11:00 AM - 4:00 PM',
        },
        closingDays: [],
        latitude: 13.7150,
        longitude: 100.5050,
        photos: [
          'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop17',
        name: 'Phone Doctor',
        description:
            'Specialized in smartphone screen replacements, battery upgrades, and water damage repair.',
        address: '567 Mobile Lane, Tech Park',
        area: 'Tech Park',
        categories: ['electronics'],
        rating: 4.6,
        reviewCount: 156,
        hours: {
          'Monday': '9:00 AM - 7:00 PM',
          'Tuesday': '9:00 AM - 7:00 PM',
          'Wednesday': '9:00 AM - 7:00 PM',
          'Thursday': '9:00 AM - 7:00 PM',
          'Friday': '9:00 AM - 7:00 PM',
          'Saturday': '10:00 AM - 5:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7050,
        longitude: 100.5120,
        photos: [
          'https://images.unsplash.com/photo-1581092335397-9583eb92d232?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),

      // Additional appliance repair shops
      RepairShop(
        id: 'shop18',
        name: 'HomeFix Appliance Repair',
        description:
            'Comprehensive repair services for all major home appliances including refrigerators, washers, dryers, and more.',
        address: '888 Household Blvd, Residential Zone',
        area: 'Residential Zone',
        categories: ['appliance'],
        rating: 4.7,
        reviewCount: 123,
        hours: {
          'Monday': '8:00 AM - 6:00 PM',
          'Tuesday': '8:00 AM - 6:00 PM',
          'Wednesday': '8:00 AM - 6:00 PM',
          'Thursday': '8:00 AM - 6:00 PM',
          'Friday': '8:00 AM - 6:00 PM',
          'Saturday': '9:00 AM - 3:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7830,
        longitude: 100.4940,
        photos: [
          'https://images.unsplash.com/photo-1507138086030-616c3b6dd768?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop19',
        name: 'Kitchen Appliance Specialists',
        description:
            'Focused on kitchen appliance repair including refrigerators, ovens, dishwashers, and small countertop appliances.',
        address: '333 Culinary Road, Gourmet District',
        area: 'Gourmet District',
        categories: ['appliance'],
        rating: 4.5,
        reviewCount: 87,
        hours: {
          'Monday': '9:00 AM - 5:00 PM',
          'Tuesday': '9:00 AM - 5:00 PM',
          'Wednesday': '9:00 AM - 5:00 PM',
          'Thursday': '9:00 AM - 5:00 PM',
          'Friday': '9:00 AM - 5:00 PM',
          'Saturday': '10:00 AM - 2:00 PM',
          'Sunday': 'Closed',
        },
        closingDays: ['Sunday'],
        latitude: 13.7700,
        longitude: 100.5000,
        photos: [
          'https://images.unsplash.com/photo-1556911220-bff31c812dba?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),

      // Multi-category shops
      RepairShop(
        id: 'shop20',
        name: 'LuxRepair Center',
        description:
            'Premium repair services for luxury goods including watches, bags, and high-end electronics.',
        address: '999 Elite Avenue, Luxury District',
        area: 'Luxury District',
        categories: ['watch', 'bag', 'electronics'],
        rating: 4.9,
        reviewCount: 165,
        hours: {
          'Monday': '10:00 AM - 7:00 PM',
          'Tuesday': '10:00 AM - 7:00 PM',
          'Wednesday': '10:00 AM - 7:00 PM',
          'Thursday': '10:00 AM - 7:00 PM',
          'Friday': '10:00 AM - 7:00 PM',
          'Saturday': '11:00 AM - 5:00 PM',
          'Sunday': 'By appointment only',
        },
        closingDays: [],
        latitude: 13.7400,
        longitude: 100.5300,
        photos: [
          'https://images.unsplash.com/photo-1556909114-44e3e9399e2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop21',
        name: 'Fashion Fix Hub',
        description:
            'One-stop repair service for all fashion items including clothing, shoes, and accessory repairs.',
        address: '555 Style Avenue, Fashion Center',
        area: 'Fashion Center',
        categories: ['clothing', 'footwear', 'bag'],
        rating: 4.7,
        reviewCount: 142,
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
        latitude: 13.7280,
        longitude: 100.5320,
        photos: [
          'https://images.unsplash.com/photo-1607082349566-187342175e2f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop22',
        name: 'Home & Tech Solutions',
        description:
            'Comprehensive repair services for both home appliances and electronics. Expert technicians with broad expertise.',
        address: '432 Multi Avenue, Central District',
        area: 'Central District',
        categories: ['appliance', 'electronics'],
        rating: 4.6,
        reviewCount: 198,
        hours: {
          'Monday': '8:00 AM - 7:00 PM',
          'Tuesday': '8:00 AM - 7:00 PM',
          'Wednesday': '8:00 AM - 7:00 PM',
          'Thursday': '8:00 AM - 7:00 PM',
          'Friday': '8:00 AM - 7:00 PM',
          'Saturday': '9:00 AM - 5:00 PM',
          'Sunday': '10:00 AM - 3:00 PM',
        },
        closingDays: [],
        latitude: 13.7450,
        longitude: 100.5200,
        photos: [
          'https://images.unsplash.com/photo-1550009158-9ebf69173e03?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
    ];
  }
}
