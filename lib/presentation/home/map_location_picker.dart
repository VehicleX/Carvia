import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({super.key});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default SF
  LatLng? _selectedPosition;
  String _address = "Searching...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _address = "Location services are disabled."; _isLoading = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         setState(() { _address = "Location permissions are denied."; _isLoading = false; });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
       setState(() { _address = "Location permissions are permanently denied."; _isLoading = false; });
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _selectedPosition = _currentPosition;
      _isLoading = false;
    });

    _getAddressFromLatLng(_currentPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = "${place.locality}, ${place.administrativeArea}";
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      setState(() => _address = "Unknown Location");
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedPosition = position.target;
  }

  void _onCameraIdle() {
    if (_selectedPosition != null) {
      _getAddressFromLatLng(_selectedPosition!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Location")),
      body: Stack(
        children: [
          _isLoading 
            ? Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14),
                onMapCreated: (controller) {},
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
          Center(
            child: Icon(Icons.location_pin, color: Theme.of(context).colorScheme.primary, size: 50),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12), blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_address, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context, _address);
                      },
                      child: Text("Confirm Location"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
