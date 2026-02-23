
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService extends ChangeNotifier {
  String _currentLocation = "New York, USA"; // Default
  final List<String> _recentLocations = ["New York, USA", "Los Angeles, CA", "Chicago, IL"];

  String get currentLocation => _currentLocation;
  List<String> get recentLocations => _recentLocations;

  LocationService() {
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocation = prefs.getString('user_location') ?? "New York, USA";
    notifyListeners();
  }

  Future<void> setLocation(String location) async {
    _currentLocation = location;
    if (!_recentLocations.contains(location)) {
      _recentLocations.insert(0, location);
      if (_recentLocations.length > 5) _recentLocations.removeLast();
    }
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_location', location);
  }
}
