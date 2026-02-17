
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, confirmed, delivered, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String vehicleName;
  final double amount;
  final DateTime date;
  final OrderStatus status;
  final String paymentMethod; 

  OrderModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.vehicleName,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
    this.creditsUsed = 0,
    this.creditsEarned = 0,
  });

  final int creditsUsed;
  final int creditsEarned;

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      vehicleName: map['vehicleName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      status: OrderStatus.values.firstWhere((e) => e.toString() == map['status'], orElse: () => OrderStatus.pending),
      paymentMethod: map['paymentMethod'] ?? 'Credit Card',
      creditsUsed: map['creditsUsed'] ?? 0,
      creditsEarned: map['creditsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status.toString(),
      'paymentMethod': paymentMethod,
      'creditsUsed': creditsUsed,
      'creditsEarned': creditsEarned,
    };
  }
}
