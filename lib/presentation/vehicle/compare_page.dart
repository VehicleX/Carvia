import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compare Vehicles", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
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
                   const SizedBox(height: 16),
                   ElevatedButton.icon(
                     onPressed: () => _showVehicleSelectionBottomSheet(context),
                     icon: const Icon(Icons.add),
                     label: const Text("Add Vehicle"),
                   ),
                ],
              ),
            );
          }

          double bestPrice = vehicles.isNotEmpty ? vehicles.map((v) => v.price).reduce(min) : 0;
          int bestYear = vehicles.isNotEmpty ? vehicles.map((v) => v.year).reduce(max) : 0;
          int bestMileage = vehicles.isNotEmpty ? vehicles.map((v) => v.mileage).reduce(min) : 0;

          VehicleModel? v1 = vehicles.isNotEmpty ? vehicles[0] : null;
          VehicleModel? v2 = vehicles.length > 1 ? vehicles[1] : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Header Row (Vehicle Names) ~15%
                Expanded(
                  flex: 15,
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()), // empty top-left
                      Expanded(child: _buildHeaderCell(context, v1)),
                      Expanded(child: _buildHeaderCell(context, v2)),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.surfaceDark),
                
                // Comparison Table ~75%
                Expanded(
                  flex: 75,
                  child: Column(
                    children: [
                      _buildRow("Price", v1, v2, (v) => "\$${v.price.toStringAsFixed(0)}", (v) => v.price <= bestPrice),
                      _buildRow("Year", v1, v2, (v) => "${v.year}", (v) => v.year >= bestYear),
                      _buildRow("Brand", v1, v2, (v) => v.brand, (v) => false),
                      _buildRow("Fuel", v1, v2, (v) => v.fuel, (v) => false),
                      _buildRow("Trans.", v1, v2, (v) => v.transmission, (v) => false),
                      // Only highlight mileage if greater than 0
                      _buildRow("Mileage", v1, v2, (v) => "${v.mileage} mi", (v) => v.mileage <= bestMileage && v.mileage > 0),
                    ],
                  ),
                ),
                
                // Bottom Area ~10%
                Expanded(
                  flex: 10,
                  child: vehicles.length < 2
                    ? Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            padding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onPressed: () => _showVehicleSelectionBottomSheet(context),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text("Add Another Vehicle", style: TextStyle(fontSize: 14)),
                        )
                      )
                    : const SizedBox(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, VehicleModel? vehicle) {
    if (vehicle == null) {
      return GestureDetector(
        onTap: () => _showVehicleSelectionBottomSheet(context),
        child: Container(
          color: Colors.transparent, // expand hit area
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
              const SizedBox(height: 4),
              const Text("Select vehicle", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${vehicle.brand} ${vehicle.model}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Provider.of<CompareService>(context, listen: false).toggleCompare(vehicle),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String parameter, VehicleModel? v1, VehicleModel? v2, String Function(VehicleModel) valueMapper, bool Function(VehicleModel) isBetter) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Parameter Name
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text(parameter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  ),
                ),
                // Vehicle 1 Value
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: v1 != null
                        ? _buildValue(valueMapper(v1), isBetter(v1))
                        : const Text("-", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                ),
                // Vehicle 2 Value
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: v2 != null
                        ? _buildValue(valueMapper(v2), isBetter(v2))
                        : const Text("-", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.surface, indent: 4, endIndent: 4),
        ],
      ),
    );
  }

  Widget _buildValue(String text, bool isBetter) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isBetter ? FontWeight.bold : FontWeight.normal,
        color: isBetter ? AppColors.primary : AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showVehicleSelectionBottomSheet(BuildContext context) {
    final compareService = Provider.of<CompareService>(context, listen: false);
    if (compareService.compareList.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can compare only 2 vehicles at a time")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const VehicleSelectionBottomSheet(),
    );
  }
}

class VehicleSelectionBottomSheet extends StatefulWidget {
  const VehicleSelectionBottomSheet({super.key});

  @override
  State<VehicleSelectionBottomSheet> createState() => _VehicleSelectionBottomSheetState();
}

class _VehicleSelectionBottomSheetState extends State<VehicleSelectionBottomSheet> {
  String _searchQuery = "";
  VehicleModel? _selectedVehicle;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    
    return Container(
      height: height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Vehicle", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search vehicles...",
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              fillColor: AppColors.surfaceDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // List
          Expanded(
            child: StreamBuilder<List<VehicleModel>>(
              stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No vehicles available", style: TextStyle(color: AppColors.textMuted)));
                }

                // Filter out already compared vehicles
                final compareService = Provider.of<CompareService>(context, listen: false);
                var availableVehicles = snapshot.data!.where((v) => !compareService.isInCompare(v.id)).toList();
                
                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  availableVehicles = availableVehicles.where((v) => 
                     v.brand.toLowerCase().contains(_searchQuery) || 
                     v.model.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (availableVehicles.isEmpty) {
                   return const Center(child: Text("No match found", style: TextStyle(color: AppColors.textMuted)));
                }

                return ListView.builder(
                  itemCount: availableVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = availableVehicles[index];
                    final isSelected = _selectedVehicle?.id == vehicle.id;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedVehicle = vehicle),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withAlpha(26) : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent, 
                            width: 2
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("${vehicle.year} • ${vehicle.fuel}", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text("\$${vehicle.price.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isSelected) 
                              const Icon(Icons.check_circle, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Confirm Button
          if (_selectedVehicle != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final success = Provider.of<CompareService>(context, listen: false).addToCompare(_selectedVehicle!);
                  Navigator.pop(context);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You can compare only 2 vehicles at a time")),
                    );
                  }
                },
                child: const Text("Add to Compare"),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
