import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String accountType; // 'admin', 'user', 'moderator'
  final String status; // 'active', 'suspended', 'pending'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool acceptedTerms;
  final bool acceptedPrivacy;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'accountType': accountType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'acceptedTerms': acceptedTerms,
      'acceptedPrivacy': acceptedPrivacy,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to convert Timestamp or String to DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      accountType: map['accountType'] ?? 'user',
      status: map['status'] ?? 'active',
      createdAt: parseDateTime(map['createdAt']),
      lastLoginAt:
          map['lastLoginAt'] != null ? parseDateTime(map['lastLoginAt']) : null,
      acceptedTerms: map['acceptedTerms'] ?? false,
      acceptedPrivacy: map['acceptedPrivacy'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? accountType,
    String? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
    );
  }
}
