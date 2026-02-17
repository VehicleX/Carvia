import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/vehicle/add_external_vehicle_page.dart';
import 'package:carvia/presentation/challan/e_challan_page.dart';
import 'package:carvia/presentation/vehicle/insurance_page.dart';
import 'package:carvia/presentation/vehicle/transfer_ownership_page.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        final vehicleService = Provider.of<VehicleService>(context, listen: false);
        await vehicleService.fetchUserVehicles(user.uid);
        // Check for insurance expiry
        await vehicleService.checkInsuranceExpiry(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
       return const Scaffold(body: Center(child: Text("Please login to view your vehicles")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vehicles"),
        centerTitle: true,
      ),
      body: Consumer<VehicleService>(
        builder: (context, vehicleService, child) {
          if (vehicleService.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }
          
          final vehicles = vehicleService.userVehicles;

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Iconsax.car, size: 80, color: AppColors.textMuted),
                   const SizedBox(height: 16),
                   const Text("You don't own any vehicles yet.", style: TextStyle(color: AppColors.textMuted)),
                   const SizedBox(height: 16),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExternalVehiclePage()));
          // Refresh list on return
          if (mounted) {
            Provider.of<VehicleService>(context, listen: false).fetchUserVehicles(user.uid);
          }
        },
        label: const Text("Add Vehicle", style: TextStyle(color: Colors.white)),
        icon: const Icon(Iconsax.add, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                image: vehicle.images.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(vehicle.images.first), fit: BoxFit.cover)
                  : null,
                color: Colors.grey.shade800,
              ),
              child: vehicle.images.isEmpty 
                  ? const Center(child: Icon(Icons.directions_car, size: 50, color: Colors.white54)) 
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${vehicle.year} ${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("OWNED", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(Iconsax.receipt, "Challans", () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => EChallanPage(
                           filterVehicleNumber: vehicle.specs['licensePlate']
                         )));
                      }),
                      _actionButton(Iconsax.document, "Insurance", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => InsurancePage(
                          vehicleName: "${vehicle.brand} ${vehicle.model}", 
                          vehicleNumber: vehicle.specs['licensePlate'] ?? "Unknown",
                          isExternal: vehicle.isExternal,
                        )));
                      }),
                      _actionButton(Iconsax.refresh, "Transfer", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TransferOwnershipPage(
                          vehicleName: "${vehicle.brand} ${vehicle.model}", 
                          vehicleNumber: vehicle.specs['licensePlate'] ?? "Unknown"
                        )));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
