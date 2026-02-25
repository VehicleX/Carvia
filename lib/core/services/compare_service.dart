
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:flutter/material.dart';

class CompareService extends ChangeNotifier {
  final List<VehicleModel> _compareList = [];
  
  List<VehicleModel> get compareList => List.unmodifiable(_compareList);

  bool toggleCompare(VehicleModel vehicle) {
    if (_compareList.any((v) => v.id == vehicle.id)) {
      _compareList.removeWhere((v) => v.id == vehicle.id);
      notifyListeners();
      return true;
    } else {
      if (_compareList.length < 2) {
        _compareList.add(vehicle);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    }
  }

  bool addToCompare(VehicleModel vehicle) {
    if (!_compareList.any((v) => v.id == vehicle.id)) {
      if (_compareList.length < 2) {
        _compareList.add(vehicle);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  bool isInCompare(String vehicleId) {
    return _compareList.any((v) => v.id == vehicleId);
  }

  void clearcompare() {
    _compareList.clear();
    notifyListeners();
  }
}
