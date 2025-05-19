import '../models/repair_shop.dart';
import 'mock_shops_extended.dart';
import 'mock_shops_extended_part2.dart';

class MockShopData {
  // Get all shops
  static List<RepairShop> getAllShops() {
    // Combine existing shops with new extended shops
    List<RepairShop> allShops = [
      RepairShop(
        id: 'shop1',
        name: 'WonWon Clothing Repair',
        description:
            'Specializing in clothing repairs, alterations, and restorations. Fast service and quality work guaranteed.',
        address: '123 Clothing St, Fashion District',
        area: 'Fashion District',
        categories: ['clothing'],
        rating: 4.5,
        reviewCount: 120,
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
        latitude: 13.7563,
        longitude: 100.5018,
        photos: [
          'https://images.unsplash.com/photo-1570310635050-39576cf72397?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop2',
        name: 'SoleFix Footwear Repair',
        description:
            'Expert footwear repairs including resoling, stitching, and restoration for all types of shoes.',
        address: '456 Shoe Lane, Downtown',
        area: 'Downtown',
        categories: ['footwear'],
        rating: 4.8,
        reviewCount: 95,
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
        latitude: 13.7308,
        longitude: 100.5382,
        photos: [
          'https://images.unsplash.com/photo-1516478177764-9fe5bd7e9717?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop3',
        name: 'TimeMaster Watch Repair',
        description:
            'Specialized in watch repair, battery replacement, and restoration of luxury timepieces.',
        address: '789 Clock Tower Rd, Central District',
        area: 'Central District',
        categories: ['watch'],
        rating: 4.9,
        reviewCount: 83,
        hours: {
          'Monday': '9:00 AM - 5:00 PM',
          'Tuesday': '9:00 AM - 5:00 PM',
          'Wednesday': '9:00 AM - 5:00 PM',
          'Thursday': '9:00 AM - 5:00 PM',
          'Friday': '9:00 AM - 5:00 PM',
          'Saturday': 'Closed',
          'Sunday': 'Closed',
        },
        closingDays: ['Saturday', 'Sunday'],
        latitude: 13.7222,
        longitude: 100.5139,
        photos: [
          'https://images.unsplash.com/photo-1509048774777-9f1cf8ab4dd0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop4',
        name: 'BagFix Leather Repair',
        description:
            'Expert repairs for handbags, purses, and leather goods. Color restoration and stitching.',
        address: '101 Bag Street, East End',
        area: 'East End',
        categories: ['bag'],
        rating: 4.3,
        reviewCount: 67,
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
        latitude: 13.7469,
        longitude: 100.5352,
        photos: [
          'https://images.unsplash.com/photo-1547949003-9792a18a2601?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop5',
        name: 'PowerFix Electronics',
        description:
            'Repairs for smartphones, tablets, computers and other electronic devices. Quick service guaranteed.',
        address: '555 Tech Avenue, Innovation District',
        area: 'Innovation District',
        categories: ['electronics'],
        rating: 4.7,
        reviewCount: 145,
        hours: {
          'Monday': '8:00 AM - 8:00 PM',
          'Tuesday': '8:00 AM - 8:00 PM',
          'Wednesday': '8:00 AM - 8:00 PM',
          'Thursday': '8:00 AM - 8:00 PM',
          'Friday': '8:00 AM - 8:00 PM',
          'Saturday': '10:00 AM - 6:00 PM',
          'Sunday': '12:00 PM - 5:00 PM',
        },
        closingDays: [],
        latitude: 13.7056,
        longitude: 100.5018,
        photos: [
          'https://images.unsplash.com/photo-1588508065123-287b28e013da?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop6',
        name: 'AppliancePro Repair',
        description:
            'Home appliance repair specialists. We fix refrigerators, washing machines, dryers, and more.',
        address: '222 Home Ave, Residential District',
        area: 'Residential District',
        categories: ['appliance'],
        rating: 4.4,
        reviewCount: 78,
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
        latitude: 13.7765,
        longitude: 100.4912,
        photos: [
          'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
      RepairShop(
        id: 'shop7',
        name: 'All-in-One Repair Shop',
        description:
            'One-stop shop for all your repair needs. We fix clothing, shoes, electronics, and more!',
        address: '777 Main Street, City Center',
        area: 'City Center',
        categories: ['clothing', 'footwear', 'electronics', 'appliance'],
        rating: 4.6,
        reviewCount: 210,
        hours: {
          'Monday': '8:00 AM - 7:00 PM',
          'Tuesday': '8:00 AM - 7:00 PM',
          'Wednesday': '8:00 AM - 7:00 PM',
          'Thursday': '8:00 AM - 7:00 PM',
          'Friday': '8:00 AM - 7:00 PM',
          'Saturday': '9:00 AM - 5:00 PM',
          'Sunday': '11:00 AM - 4:00 PM',
        },
        closingDays: [],
        latitude: 13.7500,
        longitude: 100.5167,
        photos: [
          'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=800&q=80',
        ],
      ),
    ];

    // Add shops from extended files
    allShops.addAll(MockShopsExtended.getAdditionalShops());
    allShops.addAll(MockShopsExtendedPart2.getAdditionalShops());

    return allShops;
  }

  // Get shops by category
  static List<RepairShop> getShopsByCategory(String categoryId) {
    if (categoryId == 'all') {
      return getAllShops();
    }

    return getAllShops()
        .where(
          (shop) => shop.categories.any(
            (category) => category.toLowerCase() == categoryId.toLowerCase(),
          ),
        )
        .toList();
  }
}
