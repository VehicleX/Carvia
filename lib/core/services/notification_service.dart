import 'dart:async';

import 'package:carvia/core/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize Real-time Listener
  void init(String userId) {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _notifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications(String userId) async {
    // Legacy method, init() handles updates now. 
    // Kept for manual refresh if needed.
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      // Listener will update UI automatically
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> sendNotification(String userId, NotificationModel notification) async {
     try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  // Helper for internal service use
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'data': data,
          });
    } catch (e) {
      debugPrint("Error creating notification: $e");
    }
  }
}
