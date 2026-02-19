import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/models/test_drive_model.dart';
import 'package:carvia/core/services/notification_service.dart';
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
    bool isAdding = !_wishlistIds.contains(vehicleId);
    
    if (isAdding) {
      _wishlistIds.add(vehicleId);
    } else {
      _wishlistIds.remove(vehicleId);
    }
    notifyListeners();

    try {
      // 1. Update User Wishlist
      await _firestore.collection('users').doc(userId).collection('preferences').doc('wishlist').set({
        'vehicleIds': _wishlistIds,
      });

      // 2. Update Vehicle Wishlist Count
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'wishlistCount': FieldValue.increment(isAdding ? 1 : -1),
      });
      
    } catch (e) {
      debugPrint("Error syncing wishlist: $e");
      // Revert local state if needed, but for now just log
    }
  }

  Future<void> incrementVehicleView(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error incrementing view count: $e");
    }
  }

  bool isInWishlist(String vehicleId) => _wishlistIds.contains(vehicleId);

  Future<List<VehicleModel>> fetchWishlistVehicles() async {
    if (_wishlistIds.isEmpty) return [];
    
    try {
      List<VehicleModel> vehicles = [];
      // Fetch individually for now. In prod, use whereIn with batches of 10.
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

  Future<void> fetchVehicles({
    String? brand, 
    String? type, // Added type
    String? query, 
    double? minPrice, 
    double? maxPrice,
    String? fuelType,
    String? transmission,
    int? minYear,
    int? maxYear,
    double? maxKms,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      Query queryRef = _firestore.collection('vehicles').where('status', isEqualTo: 'available');

      if (brand != null && brand.isNotEmpty && brand != 'All') {
        queryRef = queryRef.where('brand', isEqualTo: brand);
      }

      if (type != null && type.isNotEmpty && type != 'All') {
        queryRef = queryRef.where('type', isEqualTo: type);
      }
      
      // Basic filtering on server side for simple fields if indexes exist. 
      // For this demo/prototype without creating complex composite indexes manually, 
      // we fetch a larger set (limited) and filter on client.
      
      final snapshot = await queryRef.limit(100).get(); // Increased limit for client-side filtering
      List<VehicleModel> allVehicles = snapshot.docs.map((doc) => VehicleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      // Client-side filtering
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        allVehicles = allVehicles.where((v) => 
          v.brand.toLowerCase().contains(lowerQuery) || 
          v.model.toLowerCase().contains(lowerQuery)
        ).toList();
      }

      if (minPrice != null) allVehicles = allVehicles.where((v) => v.price >= minPrice).toList();
      if (maxPrice != null) allVehicles = allVehicles.where((v) => v.price <= maxPrice).toList();

      if (fuelType != null && fuelType != 'All') {
        allVehicles = allVehicles.where((v) => v.fuel.toLowerCase() == fuelType.toLowerCase()).toList();
      }

      if (transmission != null && transmission != 'All') {
        allVehicles = allVehicles.where((v) => v.transmission.toLowerCase() == transmission.toLowerCase()).toList();
      }

      if (minYear != null) allVehicles = allVehicles.where((v) => v.year >= minYear).toList();
      if (maxYear != null) allVehicles = allVehicles.where((v) => v.year <= maxYear).toList();

      if (maxKms != null) allVehicles = allVehicles.where((v) => v.mileage <= maxKms).toList();

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

  List<VehicleModel> _userVehicles = [];
  List<VehicleModel> get userVehicles => _userVehicles;

  Future<void> fetchUserVehicles(String userId) async {
    _isLoading = true;
    notifyListeners();
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

      _userVehicles = [...purchased, ...externalList];
    } catch (e) {
      debugPrint("Error fetching user vehicles: $e");
      _userVehicles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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

  // --- Test Drive Methods ---

  // --- Seller Methods ---

  Future<void> addVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Create a new document ref to get ID if not provided, or use vehicle.id
      DocumentReference docRef;
      if (vehicle.id.isEmpty) {
        docRef = _firestore.collection('vehicles').doc();
      } else {
        docRef = _firestore.collection('vehicles').doc(vehicle.id);
      }
      
      // Ensure we use the generated ID in the model
      final newVehicle = VehicleModel(
        id: docRef.id,
        brand: vehicle.brand,
        model: vehicle.model,
        year: vehicle.year,
        fuel: vehicle.fuel,
        transmission: vehicle.transmission,
        price: vehicle.price,
        mileage: vehicle.mileage,
        images: vehicle.images,
        sellerId: vehicle.sellerId,
        status: vehicle.status,
        type: vehicle.type,
        specs: vehicle.specs,
        isExternal: vehicle.isExternal,
        viewsCount: vehicle.viewsCount,
        wishlistCount: vehicle.wishlistCount,
        fullImages: vehicle.fullImages,
      );

      await docRef.set(newVehicle.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding vehicle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating vehicle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('vehicles').doc(vehicleId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting vehicle: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<VehicleModel>> getSellerVehiclesStream(String sellerId) {
    return _firestore
        .collection('vehicles')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<VehicleModel>> fetchSellerVehicles(String sellerId, {String? status}) async {
    try {
      Query query = _firestore.collection('vehicles').where('sellerId', isEqualTo: sellerId);
      
      if (status != null && status != 'All') {
        query = query.where('status', isEqualTo: status.toLowerCase());
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) => VehicleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint("Error fetching seller vehicles: $e");
      return [];
    }
  }

  Future<List<TestDriveModel>> fetchSellerTestDrives(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('test_drives')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final drives = snapshot.docs
          .map((doc) => TestDriveModel.fromMap(doc.data(), doc.id))
          .toList();
      drives.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return drives;
    } catch (e) {
      debugPrint("Error fetching seller test drives: $e");
      return [];
    }
  }

  Stream<List<TestDriveModel>> getSellerTestDrivesStream(String sellerId) {
    return _firestore
        .collection('test_drives')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final drives = snapshot.docs
              .map((doc) => TestDriveModel.fromMap(doc.data(), doc.id))
              .toList();
          drives.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
          return drives;
        });
  }

  Future<void> updateTestDriveStatus(String testDriveId, String status, String buyerId, String vehicleName) async {
    try {
      await _firestore.collection('test_drives').doc(testDriveId).update({'status': status});
      
      // Notify Buyer
      String title = status == 'approved' ? "Test Drive Approved! ✅" : "Test Drive Update";
      String body = status == 'approved' 
          ? "Your test drive for $vehicleName has been approved." 
          : "Your test drive for $vehicleName was $status.";
          
      await _notificationService.createNotification(
        userId: buyerId,
        title: title,
        body: body,
        type: "test_drive_update",
        data: {'testDriveId': testDriveId},
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating test drive: $e");
      rethrow;
    }
  }

  // Notification Service
  final NotificationService _notificationService = NotificationService();

  Future<void> bookTestDrive(TestDriveModel booking) async {
    try {
      await _firestore.collection('test_drives').add(booking.toMap());
      
      // Notify User
      await _notificationService.createNotification(
        userId: booking.userId,
        title: "Test Drive Requested",
        body: "Your request for ${booking.vehicleName} on ${booking.scheduledTime.toString().split('.')[0]} has been submitted.",
        type: "test_drive_booked",
        data: {'vehicleId': booking.vehicleId},
      );

    } catch (e) {
      debugPrint("Error booking test drive: $e");
      rethrow;
    }
  }

  // Check Insurance Expiry for User Vehicles
  Future<void> checkInsuranceExpiry(String userId) async {
    // Ensure vehicles are fetched
    if (_userVehicles.isEmpty) {
      await fetchUserVehicles(userId);
    }

    final now = DateTime.now();
    for (var vehicle in _userVehicles) {
      // Check if insurance expiry exists in specs
      if (vehicle.specs.containsKey('insuranceExpiry')) {
        try {
          // Assuming stored as ISO string or Timestamp
          DateTime expiry;
          final val = vehicle.specs['insuranceExpiry'];
          if (val is Timestamp) {
            expiry = val.toDate();
          } else if (val is String) {
            expiry = DateTime.parse(val);
          } else {
            continue;
          }

          final difference = expiry.difference(now).inDays;
          
          // Notify if expiring within 7 days and future
          if (difference >= 0 && difference <= 7) {
            final plate = vehicle.specs['licensePlate'] ?? "Vehicle";
            
            // Check if we already sent this notification today (Mock Check)
            // In real app, we'd query notifications or check local prefs.
            // For now, we just send it. logic to prevent duplicates handled by backend usually.
            
            await _notificationService.createNotification(
              userId: userId,
              title: "Insurance Expiring Soon!",
              body: "Insurance for $plate expires in $difference days.",
              type: "insurance_expiry",
              data: {'vehicleId': vehicle.id},
            );
          }
        } catch (e) {
          debugPrint("Error checking insurance for ${vehicle.id}: $e");
        }
      }
    }
  }

  Future<List<TestDriveModel>> fetchUserTestDrives(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('test_drives')
          .where('userId', isEqualTo: userId)
          .get();

      final drives = snapshot.docs
          .map((doc) => TestDriveModel.fromMap(doc.data(), doc.id))
          .toList();
      drives.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      return drives;
    } catch (e) {
      debugPrint("Error fetching test drives: $e");
      return []; // Return empty on error (or if index is missing)
    }
  }

  Stream<List<TestDriveModel>> getUserTestDrivesStream(String userId) {
    return _firestore
        .collection('test_drives')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final drives = snapshot.docs
              .map((doc) => TestDriveModel.fromMap(doc.data(), doc.id))
              .toList();
          drives.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
          return drives;
        });
  }

  Stream<List<VehicleModel>> getAllVehiclesStream() {
    return _firestore
        .collection('vehicles')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

