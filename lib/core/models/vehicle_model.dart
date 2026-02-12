
import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType { car, bike, auto, cycle, truck }
enum FuelType { petrol, diesel, electric, hybrid, none }
enum Transmission { manual, automatic, none }
enum VehicleStatus { owned, available, sold, archived }

class VehicleModel {
  final String id;
  final String ownerId;
  final String? sellerId;
  final VehicleType type;
  final String brand;
  final String model;
  final String variant;
  final int year;
  final String vehicleNumber;
  final FuelType fuelType;
  final Transmission transmission;
  final String color;
  final int kmDriven;
  final double price;
  final String description;
  final List<String> images;
  final VehicleStatus status;
  final String source; // marketplace | external
  
  final Map<String, dynamic> specifications;
  final Map<String, dynamic> aiMetadata;
  final Map<String, dynamic> location;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.ownerId,
    this.sellerId,
    required this.type,
    required this.brand,
    required this.model,
    required this.variant,
    required this.year,
    required this.vehicleNumber,
    required this.fuelType,
    required this.transmission,
    required this.color,
    required this.kmDriven,
    required this.price,
    required this.description,
    required this.images,
    required this.status,
    this.source = 'marketplace',
    this.specifications = const {},
    this.aiMetadata = const {},
    this.location = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      sellerId: map['sellerId'],
      type: VehicleType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => VehicleType.car
      ),
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      variant: map['variant'] ?? '',
      year: map['year'] ?? 0,
      vehicleNumber: map['vehicleNumber'] ?? '',
      fuelType: FuelType.values.firstWhere(
        (e) => e.name == map['fuelType'],
        orElse: () => FuelType.petrol
      ),
      transmission: Transmission.values.firstWhere(
        (e) => e.name == map['transmission'],
        orElse: () => Transmission.manual
      ),
      color: map['color'] ?? '',
      kmDriven: map['kmDriven'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VehicleStatus.available
      ),
      source: map['source'] ?? 'marketplace',
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      aiMetadata: Map<String, dynamic>.from(map['aiMetadata'] ?? {}),
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'sellerId': sellerId,
      'type': type.name,
      'brand': brand,
      'model': model,
      'variant': variant,
      'year': year,
      'vehicleNumber': vehicleNumber,
      'fuelType': fuelType.name,
      'transmission': transmission.name,
      'color': color,
      'kmDriven': kmDriven,
      'price': price,
      'description': description,
      'images': images,
      'status': status.name,
      'source': source,
      'specifications': specifications,
      'aiMetadata': aiMetadata,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
