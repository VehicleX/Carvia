
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String vehicleId;
  final String buyerId;
  final String sellerId;
  final double price;
  final String paymentId;
  final DateTime purchaseDate;

  PurchaseModel({
    required this.id,
    required this.vehicleId,
    required this.buyerId,
    required this.sellerId,
    required this.price,
    required this.paymentId,
    required this.purchaseDate,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseModel(
      id: id,
      vehicleId: map['vehicleId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      paymentId: map['paymentId'] ?? '',
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'price': price,
      'paymentId': paymentId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
    };
  }
}
