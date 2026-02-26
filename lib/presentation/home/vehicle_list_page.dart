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
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No vehicles found"));
                }
                
                return _buildVehicleList(snapshot.data!);
              },
            ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> list) {
    if (list.isEmpty) {
       return Center(child: Text("No vehicles match this category"));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final vehicle = list[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1)
          ),
          child: InkWell(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: vehicle.images.isNotEmpty
                      ? VehicleImage(src: vehicle.images.first, fit: BoxFit.cover)
                      : Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), child: Icon(Icons.car_repair, size: 50)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${vehicle.brand} ${vehicle.model}", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      SizedBox(height: 4),
                      Text(
                        "\$${vehicle.price.toStringAsFixed(0)}", 
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)
                      ),
                       SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.location, size: 14, color: Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 4),
                          Text(vehicle.location.isNotEmpty ? vehicle.location : "Location N/A", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
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
