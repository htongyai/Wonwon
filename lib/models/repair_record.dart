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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'itemFixed': itemFixed,
      'price': price,
      'date': Timestamp.fromDate(date),
      'duration': duration?.inDays,
      'notes': notes,
      'satisfactionRating': satisfactionRating,
      'category': category,
      'subService': subService,
    };
  }

  factory RepairRecord.fromMap(Map<String, dynamic> map) {
    return RepairRecord(
      id: map['id']?.toString() ?? '',
      shopId: map['shopId']?.toString() ?? '',
      shopName: map['shopName']?.toString() ?? '',
      itemFixed: map['itemFixed']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble(),
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      duration:
          map['duration'] != null ? Duration(days: map['duration']) : null,
      notes: map['notes']?.toString(),
      satisfactionRating: map['satisfactionRating'] as int?,
      category: map['category']?.toString() ?? '',
      subService: map['subService']?.toString() ?? '',
    );
  }
}
