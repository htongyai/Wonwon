import 'package:cloud_firestore/cloud_firestore.dart';

class RepairRecord {
  final String id;
  final String shopId;
  final String shopName;
  final String itemFixed;
  final double? price;
  final DateTime date;
  final Duration? duration;
  final String? notes;
  final int? satisfactionRating; // 1-5 rating
  final String category;
  final String subService;
  final List<String> photos;

  RepairRecord({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.itemFixed,
    this.price,
    required this.date,
    this.duration,
    this.notes,
    this.satisfactionRating,
    required this.category,
    required this.subService,
    this.photos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'itemFixed': itemFixed,
      'price': price,
      'date': Timestamp.fromDate(date),
      'duration': duration?.inMinutes,
      'notes': notes,
      'satisfactionRating': satisfactionRating,
      'category': category,
      'subService': subService,
      'photos': photos,
    };
  }

  factory RepairRecord.fromMap(Map<String, dynamic> map) {
    return RepairRecord(
      id: map['id']?.toString() ?? '',
      shopId: map['shopId']?.toString() ?? '',
      shopName: map['shopName']?.toString() ?? '',
      itemFixed: map['itemFixed']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble(),
      date: (map['date'] is Timestamp) ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      duration:
          map['duration'] != null ? Duration(minutes: map['duration'] as int) : null,
      notes: map['notes']?.toString(),
      satisfactionRating: map['satisfactionRating'] as int?,
      category: map['category']?.toString() ?? '',
      subService: map['subService']?.toString() ?? '',
      photos: (map['photos'] is List)
          ? (map['photos'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}
