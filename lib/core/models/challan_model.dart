
import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallanStatus { unpaid, paid, disputed }

class ChallanModel {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String ownerId;
  final String violationType;
  final double fineAmount;
  final String issuedBy; // Police User ID
  final DateTime issuedAt;
  final Map<String, dynamic> location;
  final ChallanStatus status;
  final String? evidenceImageUrl;
  final DateTime? paymentDueDate;
  final String? paymentId;

  ChallanModel({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.ownerId,
    required this.violationType,
    required this.fineAmount,
    required this.issuedBy,
    required this.issuedAt,
    this.location = const {},
    required this.status,
    this.paymentId,
    this.evidenceImageUrl,
    this.paymentDueDate,
  });

  factory ChallanModel.fromMap(Map<String, dynamic> map, String id) {
    return ChallanModel(
      id: id,
      vehicleId: map['vehicleId'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      ownerId: map['ownerId'] ?? '',
      violationType: map['violationType'] ?? '',
      fineAmount: (map['fineAmount'] ?? 0).toDouble(),
      issuedBy: map['issuedBy'] ?? '',
      issuedAt: (map['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      status: ChallanStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChallanStatus.unpaid
      ),
      paymentId: map['paymentId'],
      evidenceImageUrl: map['evidenceImageUrl'],
      paymentDueDate: (map['paymentDueDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'ownerId': ownerId,
      'violationType': violationType,
      'fineAmount': fineAmount,
      'issuedBy': issuedBy,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'location': location,
      'status': status.name,
      'paymentId': paymentId,
      'evidenceImageUrl': evidenceImageUrl,
      'paymentDueDate': paymentDueDate != null ? Timestamp.fromDate(paymentDueDate!) : null,
    };
  }
}
