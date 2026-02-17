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
  final String type; // Car, Bike, Truck, etc.
  final bool isExternal;
  final Map<String, dynamic> specs;
  final int viewsCount;
  final int wishlistCount;
  final List<Map<String, dynamic>> fullImages; // Detailed image data

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
    this.type = 'Car',
    this.specs = const {},
    this.isExternal = false,
    this.viewsCount = 0,
    this.wishlistCount = 0,
    this.fullImages = const [],
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
      type: map['type'] ?? 'Car',
      specs: Map<String, dynamic>.from(map['specs'] ?? {}),
      isExternal: map['isExternal'] ?? false,
      viewsCount: map['viewsCount'] ?? 0,
      wishlistCount: map['wishlistCount'] ?? 0,
      fullImages: List<Map<String, dynamic>>.from(map['fullImages'] ?? []),
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
      'type': type,
      'specs': specs,
      'isExternal': isExternal,
      'viewsCount': viewsCount,
      'wishlistCount': wishlistCount,
      'fullImages': fullImages,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? brand,
    String? model,
    int? year,
    String? fuel,
    String? transmission,
    double? price,
    int? mileage,
    List<String>? images,
    String? sellerId,
    String? status,
    String? type,
    bool? isExternal,
    Map<String, dynamic>? specs,
    int? viewsCount,
    int? wishlistCount,
    List<Map<String, dynamic>>? fullImages,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuel: fuel ?? this.fuel,
      transmission: transmission ?? this.transmission,
      price: price ?? this.price,
      mileage: mileage ?? this.mileage,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      type: type ?? this.type,
      isExternal: isExternal ?? this.isExternal,
      specs: specs ?? this.specs,
      viewsCount: viewsCount ?? this.viewsCount,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      fullImages: fullImages ?? this.fullImages,
    );
  }
}
