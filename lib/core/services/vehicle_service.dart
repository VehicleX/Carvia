import 'package:carvia/core/models/vehicle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VehicleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<VehicleModel> _featuredVehicles = [];
  List<VehicleModel> _recommendedVehicles = [];
  bool _isLoading = false;

  List<VehicleModel> get featuredVehicles => _featuredVehicles;
  List<VehicleModel> get recommendedVehicles => _recommendedVehicles;
  bool get isLoading => _isLoading;

  final List<String> _wishlistIds = [];
  List<String> get wishlistIds => _wishlistIds;

  // Initialize wishlist (call this on startup or login)
  Future<void> initWishlist(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).collection('preferences').doc('wishlist').get();
      if (doc.exists && doc.data() != null) {
        _wishlistIds.clear();
        _wishlistIds.addAll(List<String>.from(doc.data()!['vehicleIds'] ?? []));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading wishlist: $e");
    }
  }

  Future<void> toggleWishlist(String userId, String vehicleId) async {
    if (_wishlistIds.contains(vehicleId)) {
      _wishlistIds.remove(vehicleId);
    } else {
      _wishlistIds.add(vehicleId);
    }
    notifyListeners();

    try {
      await _firestore.collection('users').doc(userId).collection('preferences').doc('wishlist').set({
        'vehicleIds': _wishlistIds,
      });
    } catch (e) {
      debugPrint("Error syncing wishlist: $e");
      // Rollback on error? For now, we keep local state optimistic.
    }
  }

  bool isInWishlist(String vehicleId) => _wishlistIds.contains(vehicleId);

  Future<List<VehicleModel>> fetchWishlistVehicles() async {
    if (_wishlistIds.isEmpty) return [];
    
    // Firestore 'where in' is limited to 10. We might need to batch or fetch individually if list is huge.
    // For simplicity, we'll fetch individually or use 'whereIn' batches.
    // Hack for short list:
    if (_wishlistIds.length > 10) {
       // Just fetch first 10 for now or implement batching logic
       // A better approach for production is fetching all and filtering, or separate collection.
       // Let's implement a simple fetch-by-id loop or "where documentId in ..."
    }

    try {
      // Fetching individually guarantees we get them all (though n reads)
      // Optimazation: split into chunks of 10
      List<VehicleModel> vehicles = [];
      
      // Simple loop for now (assuming not too many for this demo)
      for(String id in _wishlistIds) {
        final v = await getVehicleById(id);
        if(v != null) vehicles.add(v);
      }
      return vehicles;
    } catch (e) {
      debugPrint("Error fetching wishlist items: $e");
      return [];
    }
  }

  Future<void> fetchVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('vehicles')
          .where('status', isEqualTo: 'available')
          .limit(20)
          .get();

      final allVehicles = snapshot.docs.map((doc) => VehicleModel.fromMap(doc.data(), doc.id)).toList();

      if (allVehicles.isNotEmpty) {
        _featuredVehicles = allVehicles.take(5).toList();
        _recommendedVehicles = allVehicles.skip(5).toList();
      } else {
        _featuredVehicles = [];
        _recommendedVehicles = [];
      }

    } catch (e) {
      debugPrint("Error fetching vehicles: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VehicleModel>> fetchUserVehicles(String userId) async {
    try {
      // 1. Fetch Purchased
      final purchasedSnapshot = await _firestore
          .collection('vehicles')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      final purchased = purchasedSnapshot.docs.map((doc) => VehicleModel.fromMap(doc.data(), doc.id)).toList();

      // 2. Fetch External
      final externalSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('external_vehicles')
          .get();
      
      final externalList = externalSnapshot.docs.map((doc) => VehicleModel.fromMap(doc.data(), doc.id)).toList();

      return [...purchased, ...externalList];
    } catch (e) {
      debugPrint("Error fetching user vehicles: $e");
      return [];
    }
  }

  Future<void> addExternalVehicle(String userId, VehicleModel vehicle) async {
    try {
       await _firestore
          .collection('users')
          .doc(userId)
          .collection('external_vehicles')
          .add(vehicle.toMap());
       notifyListeners();
    } catch (e) {
      debugPrint("Error adding external vehicle: $e");
      rethrow;
    }
  }

  Future<VehicleModel?> getVehicleById(String id) async {
    try {
      final doc = await _firestore.collection('vehicles').doc(id).get();
      if (doc.exists) {
        return VehicleModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching vehicle detail: $e");
    }
    return null;
  }
}
