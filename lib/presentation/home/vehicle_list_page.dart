import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class VehicleListPage extends StatelessWidget {
  final String title;
  final List<VehicleModel>? vehicles;

  // If vehicles is null, we could fetch from service based on title/type logic, 
  // but for now let's assume we pass filtered list or fetch all if null.
  const VehicleListPage({super.key, required this.title, this.vehicles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: vehicles != null 
          ? _buildVehicleList(vehicles!)
          : StreamBuilder<List<VehicleModel>>(
              stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No vehicles found"));
                }
                
                return _buildVehicleList(snapshot.data!);
              },
            ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> list) {
    if (list.isEmpty) {
       return const Center(child: Text("No vehicles match this category"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final vehicle = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: vehicle.images.isNotEmpty
                      ? VehicleImage(src: vehicle.images.first, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300], child: const Icon(Icons.car_repair, size: 50)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${vehicle.brand} ${vehicle.model}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${vehicle.price.toStringAsFixed(0)}", 
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
                      ),
                       const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.location, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(vehicle.location.isNotEmpty ? vehicle.location : "Location N/A", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
