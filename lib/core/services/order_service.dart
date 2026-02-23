
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
        transaction.update(userRef, {'credits': newBalance, 'updatedAt': FieldValue.serverTimestamp()});

        // 4. Update Vehicle Status to sold
        final vehicleRef = _firestore.collection('vehicles').doc(order.vehicleId);
        transaction.update(vehicleRef, {'status': 'sold'});

        // 5. Create Order with auto-ID
        final orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, {
          ...order.toMap(),
          'orderId': orderRef.id,
          'date': FieldValue.serverTimestamp(),
        });
      });

      // Post-transaction: send notification
      await _firestore.collection('users').doc(order.userId).collection('notifications').add({
        'title': 'Order Confirmed! 🎉',
        'body': 'Your order for ${order.vehicleName} has been placed. You earned ${order.creditsEarned} credits!',
        'type': 'order',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint("Error creating order: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seller calls this when the physical vehicle has been handed to the buyer.
  /// Atomically:
  ///   1. Marks the order as delivered
  ///   2. Stores the vehicle under the buyer's owned_vehicles subcollection
  ///   3. Awards delivery credits to the buyer
  ///   4. Sends a delivery notification
  Future<void> deliverOrder({
    required String orderId,
    required String buyerId,
    required String sellerId,
    required String vehicleId,
    required String vehicleName,
    int deliveryCredits = 50,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // -- Fetch vehicle data first (outside transaction to keep it short) --
      final vehicleDoc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (!vehicleDoc.exists) throw "Vehicle not found";
      final vehicleData = vehicleDoc.data()!;

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderDoc = await transaction.get(orderRef);
        if (!orderDoc.exists) throw "Order not found";

        final currentStatus = orderDoc.data()!['status'] ?? '';
        if (currentStatus == OrderStatus.delivered.toString()) {
          throw "Order already delivered";
        }

        final userRef = _firestore.collection('users').doc(buyerId);
        final userDoc = await transaction.get(userRef);
        int currentCredits = userDoc.data()?['credits'] ?? 0;

        // 1. Update order status
        transaction.update(orderRef, {
          'status': OrderStatus.delivered.toString(),
          'deliveredAt': FieldValue.serverTimestamp(),
          'creditsEarned': FieldValue.increment(deliveryCredits),
        });

        // 2. Add to buyer's owned_vehicles subcollection
        final ownedRef = _firestore
            .collection('users')
            .doc(buyerId)
            .collection('owned_vehicles')
            .doc(vehicleId);
        transaction.set(ownedRef, {
          ...vehicleData,
          'id': vehicleId,
          'ownerId': buyerId,
          'purchasedAt': FieldValue.serverTimestamp(),
          'orderId': orderId,
        });

        // 3. Award delivery credits to buyer
        transaction.update(userRef, {
          'credits': currentCredits + deliveryCredits,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // 4. Send delivery notification (outside transaction)
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('notifications')
          .add({
        'title': '🚗 Vehicle Delivered!',
        'body':
            'Your $vehicleName has been delivered! You earned $deliveryCredits credits. Check My Vehicles.',
        'type': 'delivery',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {'vehicleId': vehicleId, 'orderId': orderId},
      });

      debugPrint("Order $orderId delivered. $deliveryCredits credits awarded to $buyerId.");
    } catch (e) {
      debugPrint("Error delivering order: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates order status (e.g., pending → confirmed)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating order status: $e");
      rethrow;
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
