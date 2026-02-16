import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String fuel;
  final String transmission;
  final double price;
  final int mileage;
  final List<String> images;
  final String sellerId;
  final String status; // available, sold
  final bool isExternal;
  final Map<String, dynamic> specs;

  VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    required this.transmission,
    required this.price,
    required this.mileage,
    required this.images,
    required this.sellerId,
    required this.status,
    this.specs = const {},
    this.isExternal = false,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      fuel: map['fuel'] ?? 'Petrol',
      transmission: map['transmission'] ?? 'Automatic',
      price: (map['price'] ?? 0).toDouble(),
      mileage: map['mileage'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      sellerId: map['sellerId'] ?? '',
      status: map['status'] ?? 'available',
      specs: Map<String, dynamic>.from(map['specs'] ?? {}),
      isExternal: map['isExternal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'year': year,
      'fuel': fuel,
      'transmission': transmission,
      'price': price,
      'mileage': mileage,
      'images': images,
      'sellerId': sellerId,
      'status': status,
      'specs': specs,
      'isExternal': isExternal,
    };
  }
}
