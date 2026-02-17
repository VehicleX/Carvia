import 'dart:math';

import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ChallanService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Fetch challans for vehicles owned by the current user
  Future<List<ChallanModel>> fetchOwnedChallans(String ownerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('challans')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      return snapshot.docs.map((doc) => ChallanModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint("Error fetching owned challans: $e");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Case 2: Request Access for Non-Owned Vehicle
  // 1. Check if vehicle exists
  // 2. Generate OTP and store in `challan_access_requests`
  // 3. Mock Email Sending to Owner
  Future<Map<String, dynamic>> requestAccess(String vehicleNumber, String requesterId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Find Vehicle
      final vehicleQuery = await _firestore
          .collection('vehicles')
          .where('vehicleNumber', isEqualTo: vehicleNumber) // Ensure vehicleNumber is indexed
          .limit(1)
          .get();

      if (vehicleQuery.docs.isEmpty) {
        throw "Vehicle not found";
      }

      final vehicle = vehicleQuery.docs.first;
      final ownerId = vehicle.data()['ownerId'];
      final ownerEmail = vehicle.data()['ownerEmail'] ?? "owner@example.com"; // Mock if missing

      if (ownerId == requesterId) {
        return {'status': 'owned', 'vehicleId': vehicle.id};
      }

      // 2. Generate OTP
      final otp = (100000 + Random().nextInt(900000)).toString(); // 6-digit OTP
      final requestId = const Uuid().v4();

      await _firestore.collection('challan_access_requests').doc(requestId).set({
        'vehicleNumber': vehicleNumber,
        'vehicleId': vehicle.id,
        'ownerId': ownerId,
        'requesterId': requesterId,
        'otp': otp, // In prod, hash this!
        'status': 'pending',
        'createdAt': DateTime.now(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
      });

      // 3. Mock Email Send
      debugPrint("EMAIL SENT TO $ownerEmail: Your OTP is $otp");

      // 4. Send Notification to Owner
      final _notificationService = NotificationService(); // In real app, inject via Provider/GetIt
      await _notificationService.createNotification(
        userId: ownerId,
        title: "Access Request",
        body: "Someone requested access to view challans of $vehicleNumber.",
        type: "challan_access_request",
        data: {'requestId': requestId, 'vehicleNumber': vehicleNumber},
      );

      return {'status': 'otp_sent', 'requestId': requestId, 'email': ownerEmail};

    } catch (e) {
      debugPrint("Error requesting access: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify OTP and Grant Access
  Future<String?> verifyAccess(String requestId, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docRef = _firestore.collection('challan_access_requests').doc(requestId);
      final doc = await docRef.get();

      if (!doc.exists) throw "Request not found";

      final data = doc.data()!;
      if (data['status'] == 'verified') return data['accessToken'];
      if (data['status'] == 'expired') throw "OTP Expired";

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        await docRef.update({'status': 'expired'});
        throw "OTP Expired";
      }

      if (data['otp'] == otp) {
        // Valid OTP
        final accessToken = const Uuid().v4();
        await docRef.update({
          'status': 'verified',
          'accessToken': accessToken,
          'accessExpiresAt': DateTime.now().add(const Duration(minutes: 10)),
        });
        return accessToken;
      } else {
        throw "Invalid OTP";
      }
    } catch (e) {
      debugPrint("Verification failed: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Challans with Access Token
  Future<List<ChallanModel>> fetchChallansWithToken(String vehicleNumber, String accessToken) async {
     _isLoading = true;
    notifyListeners();
    try {
      // In real backend, we validate token.
      // Here, we trust the caller has traversed the verifyAccess flow or we re-verify if needed.
      // For firestore direct access, we'd need a custom cloud function or permissive rules (not ideal for prod).
      // Since this is a client-side simulation of a secure flow:
      
      return await _fetchChallansByNumber(vehicleNumber);
    } catch (e) {
      rethrow; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ChallanModel>> _fetchChallansByNumber(String vehicleNumber) async {
    final snapshot = await _firestore
          .collection('vehicles')
          .where('vehicleNumber', isEqualTo: vehicleNumber)
          .limit(1)
          .get();

    if (snapshot.docs.isEmpty) return [];
    
    final vehicleId = snapshot.docs.first.id;
    
    final challanSnap = await _firestore
        .collection('challans')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    return challanSnap.docs.map((doc) => ChallanModel.fromMap(doc.data(), doc.id)).toList();
  }

  // New method to fetch for a list of vehicles (both external and internal)
  Future<List<ChallanModel>> fetchChallansForVehicles(List<String> vehicleNumbers) async {
    if (vehicleNumbers.isEmpty) return [];

    // _isLoading = true; 
    // notifyListeners(); // Removed to prevent setState during build in FutureBuilder
    
    List<ChallanModel> allChallans = [];

    try {
      for (var number in vehicleNumbers) {
         // Query challans directly by vehicleNumber
         // Ensure number is uppercased if your DB stores them that way
         // final normalizedNumber = number.toUpperCase().replaceAll(' ', ''); 
         
         // Try exact match first (as entered by user)
         var snap = await _firestore.collection('challans').where('vehicleNumber', isEqualTo: number).get();
         
         if (snap.docs.isEmpty) {
            debugPrint("No challans found for $number (exact match)");
         } else {
            debugPrint("Found ${snap.docs.length} challans for $number");
         }

         allChallans.addAll(snap.docs.map((d) => ChallanModel.fromMap(d.data(), d.id)));
      }
      
    } catch (e) {
      debugPrint("Error fetching vehicle challans: $e");
    } 
    // finally {
    //   _isLoading = false;
    //   notifyListeners();
    // }
    return allChallans;
  }
}
