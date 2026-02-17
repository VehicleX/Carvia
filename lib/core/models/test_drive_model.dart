import 'package:cloud_firestore/cloud_firestore.dart';

class TestDriveModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String vehicleName;
  final String vehicleImage;
  final DateTime scheduledTime;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;

  TestDriveModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleImage,
    required this.scheduledTime,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'vehicleImage': vehicleImage,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      // 'id' is checking document ID, so typically not stored in the map unless needed
    };
  }

  factory TestDriveModel.fromMap(Map<String, dynamic> map, String id) {
    return TestDriveModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      vehicleName: map['vehicleName'] ?? 'Unknown Vehicle',
      vehicleImage: map['vehicleImage'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
