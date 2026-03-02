
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService extends ChangeNotifier {
  String _currentLocation = "Current Location"; // Default - no location filter applied
  final List<String> _recentLocations = ["Mumbai, India", "Delhi, India", "Bangalore, India"];

  String get currentLocation => _currentLocation;
  List<String> get recentLocations => _recentLocations;

  LocationService() {
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocation = prefs.getString('user_location') ?? "Current Location";
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
