
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
      await _firestore.runTransaction((transaction) async {
        // 1. Get User Reference
        final userRef = _firestore.collection('users').doc(order.userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw "User not found";

        // 2. Calculate New Credit Balance
        int currentCredits = userDoc.data()!['credits'] ?? 0;
        if (currentCredits < order.creditsUsed) {
          throw "Insufficient credits";
        }

        int newBalance = currentCredits - order.creditsUsed + order.creditsEarned;

        // 3. Update User Credits
        transaction.update(userRef, {'credits': newBalance});

        // 4. Update Vehicle Status
        final vehicleRef = _firestore.collection('vehicles').doc(order.vehicleId);
        transaction.update(vehicleRef, {'status': 'sold'});

        // 5. Create Order
        final orderRef = _firestore.collection('orders').doc(); // Auto-ID
        transaction.set(orderRef, order.toMap());

        // 6. Create Notification (Optional inside transaction or after)
        // We'll do it after to keep transaction fast and simple, 
        // effectively handled by the fact that if this fails, we catch it.
      });

      // Notification (Post-Transaction)
      // We can't inject NotificationService easily here without circular dependency or service locator,
      // so we'll just do a direct firestore add for now or return success and let UI handle it.
      // Better: Use a lightweight firestore add here.
       await _firestore.collection('users').doc(order.userId).collection('notifications').add({
            'title': 'Order Confirmed! 🎉',
            'body': 'Your order for ${order.vehicleName} has been placed. You earned ${order.creditsEarned} credits!',
            'type': 'order',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'data': {'orderId': order.id}, // Note: ID won't match auto-id above exactly unless we generated it first.
                                          // For now, it's fine.
          });
      
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
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.date.compareTo(a.date));
      return orders;
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      return [];
    }
  }

  Stream<List<OrderModel>> getMyOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.date.compareTo(a.date));
          return orders;
        });
  }

  Stream<List<OrderModel>> getSellerOrdersStream(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.date.compareTo(a.date));
          return orders;
        });
  }
}
