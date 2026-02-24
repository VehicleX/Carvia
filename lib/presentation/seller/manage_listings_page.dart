import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class ManageListingsPage extends StatefulWidget {
  const ManageListingsPage({super.key});

  @override
  State<ManageListingsPage> createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventory", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Sold"),
            Tab(text: "Drafts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ListingsTab(status: 'active'),
          _ListingsTab(status: 'sold'),
          _ListingsTab(status: 'draft'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehiclePage()));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}

class _ListingsTab extends StatefulWidget {
  final String status;
  const _ListingsTab({required this.status});

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false).getSellerVehiclesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allVehicles = snapshot.data ?? [];
        final vehicles = allVehicles.where((v) => v.status == widget.status).toList();

        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.car, size: 60, color: AppColors.textMuted.withValues(alpha:0.3)),
                const SizedBox(height: 16),
                Text("No ${widget.status} listings", style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return _buildVehicleCard(context, vehicle);
          },
        );
      },
    );
  }

  void _handleAction(String value, VehicleModel vehicle) {
    final vehicleService = Provider.of<VehicleService>(context, listen: false);
    if (value == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehiclePage(vehicle: vehicle)));
    } else if (value == 'delete') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Vehicle"),
          content: const Text("Are you sure you want to delete this listing?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                vehicleService.deleteVehicle(vehicle.id);
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else if (value == 'mark_sold') {
      vehicleService.updateVehicle(vehicle.copyWith(status: 'sold'));
    } else if (value == 'mark_active') {
      vehicleService.updateVehicle(vehicle.copyWith(status: 'active'));
    }
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: vehicle.images.isNotEmpty
                    ? VehicleImage(src: vehicle.images.first, height: 180, width: double.infinity)
                    : Container(height: 180, color: Colors.grey[800], child: const Icon(Icons.directions_car, color: Colors.white, size: 50)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "\$${vehicle.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                      onSelected: (value) => _handleAction(value, vehicle),
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(value: 'edit', child: Text("Edit")),
                          if (vehicle.status == 'active')
                            const PopupMenuItem(value: 'mark_sold', child: Text("Mark as Sold")),
                           if (vehicle.status == 'sold')
                            const PopupMenuItem(value: 'mark_active', child: Text("Mark as Active")),
                          const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                        ];
                      },
                    ),
                  ],
                ),
                Text("${vehicle.year} • ${vehicle.mileage} km", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat(Iconsax.eye, "${vehicle.viewsCount}"),
                    const SizedBox(width: 16),
                    _buildStat(Iconsax.heart, "${vehicle.wishlistCount}"),
                    const Spacer(),
                    if (widget.status == 'active')
                       ElevatedButton(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehiclePage(vehicle: vehicle)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          side: BorderSide(color: AppColors.textMuted.withValues(alpha:0.2)),
                        ),
                        child: const Text("Edit"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
