
import 'package:carvia/core/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('orders').add(order.toMap());
      
      // Optionally update vehicle status to 'sold'
      await _firestore.collection('vehicles').doc(order.vehicleId).update({'status': 'sold'});
      
    } catch (e) {
      debugPrint("Error creating order: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderModel>> fetchMyOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      return [];
    }
  }
}
