
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:flutter/material.dart';

class CompareService extends ChangeNotifier {
  final List<VehicleModel> _compareList = [];
  
  List<VehicleModel> get compareList => List.unmodifiable(_compareList);

  void toggleCompare(VehicleModel vehicle) {
    if (_compareList.any((v) => v.id == vehicle.id)) {
      _compareList.removeWhere((v) => v.id == vehicle.id);
    } else {
      if (_compareList.length < 3) {
        _compareList.add(vehicle);
      } else {
        // Optional: Notify user that max is 3 via a callback or return value
        // For now, we simple don't add.
      }
    }
    notifyListeners();
  }

  bool isInCompare(String vehicleId) {
    return _compareList.any((v) => v.id == vehicleId);
  }

  void clearcompare() {
    _compareList.clear();
    notifyListeners();
  }
}
