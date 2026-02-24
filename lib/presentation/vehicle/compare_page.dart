import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compare Vehicles", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear All",
            onPressed: () {
              Provider.of<CompareService>(context, listen: false).clearcompare();
            },
          ),
        ],
      ),
      body: Consumer<CompareService>(
        builder: (context, compareService, child) {
          final vehicles = compareService.compareList;
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.compare_arrows, size: 64, color: AppColors.textMuted),
                   const SizedBox(height: 16),
                   const Text("No vehicles to compare", style: TextStyle(color: AppColors.textMuted)),
                   const SizedBox(height: 8),
                   const Text("Add vehicles from their detail page.", style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelsColumn(context),
                ...vehicles.map((v) => _buildVehicleColumn(context, v)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabelsColumn(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 140), // Space for image
          _buildLabel("Price"),
          _buildLabel("Year"),
          _buildLabel("Fuel"),
          _buildLabel("Trans."),
          _buildLabel("Mileage"),
          _buildLabel("Brand"),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted)),
    );
  }

  Widget _buildVehicleColumn(BuildContext context, VehicleModel vehicle) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VehicleImage(
                src: vehicle.images.isNotEmpty ? vehicle.images.first : "",
                height: 120,
                width: 160,
              ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                     Provider.of<CompareService>(context, listen: false).toggleCompare(vehicle);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("${vehicle.brand} ${vehicle.model}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, maxLines: 2),
          const SizedBox(height: 8),
           _buildValue("\$${vehicle.price.toStringAsFixed(0)}", isPrimary: true),
           _buildValue("${vehicle.year}"),
           _buildValue(vehicle.fuel),
           _buildValue(vehicle.transmission),
           _buildValue("${vehicle.mileage} mi"),
           _buildValue(vehicle.brand),
        ],
      ),
    );
  }

  Widget _buildValue(String text, {bool isPrimary = false}) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text, 
        style: TextStyle(
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: isPrimary ? AppColors.primary : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
