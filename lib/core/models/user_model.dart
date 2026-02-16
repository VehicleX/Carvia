
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  buyer,
  seller,
  police,
}

enum AccountType {
  individual,
  company,
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final AccountType? accountType; // Only for sellers
  final String? profileImage;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> address;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.accountType,
    this.profileImage,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.address = const {},
    this.preferences = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.buyer,
      ),
      accountType: map['accountType'] != null
          ? AccountType.values.firstWhere(
              (e) => e.name == map['accountType'],
              orElse: () => AccountType.individual,
            )
          : null,
      profileImage: map['profileImage'],
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: Map<String, dynamic>.from(map['address'] ?? {}),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'accountType': accountType?.name,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'address': address,
      'preferences': preferences,
    };
  }
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    AccountType? accountType,
    String? profileImage,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? address,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      preferences: preferences ?? this.preferences,
    );
  }
}
