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

  RepairRecord({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.itemFixed,
    this.price,
    required this.date,
    this.duration,
    this.notes,
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
    };
  }

  factory RepairRecord.fromMap(Map<String, dynamic> map) {
    return RepairRecord(
      id: map['id'] as String,
      shopId: map['shopId'] as String,
      shopName: map['shopName'] as String,
      itemFixed: map['itemFixed'] as String,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      date: (map['date'] as Timestamp).toDate(),
      duration:
          map['duration'] != null ? Duration(days: map['duration']) : null,
      notes: map['notes'] as String?,
    );
  }
}
