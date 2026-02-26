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
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          indicatorColor: Theme.of(context).colorScheme.outline,
          tabs: [
            Tab(text: "Active"),
            Tab(text: "Sold"),
            Tab(text: "Drafts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ListingsTab(status: 'active'),
          _ListingsTab(status: 'sold'),
          _ListingsTab(status: 'draft'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehiclePage()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Iconsax.add, color: Theme.of(context).colorScheme.onSurface),
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
    if (user == null) return Center(child: Text("Please login"));

    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false).getSellerVehiclesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        final allVehicles = snapshot.data ?? [];
        final vehicles = allVehicles.where((v) => v.status == widget.status).toList();

        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.car, size: 60, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                SizedBox(height: 16),
                Text("No ${widget.status} listings", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: vehicles.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
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
          title: Text("Delete Vehicle"),
          content: Text("Are you sure you want to delete this listing?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            TextButton(
              onPressed: () {
                vehicleService.deleteVehicle(vehicle.id);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
          BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: vehicle.images.isNotEmpty
                    ? VehicleImage(src: vehicle.images.first, height: 180, width: double.infinity)
                    : Container(height: 180, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), child: Icon(Icons.directions_car, color: Theme.of(context).colorScheme.onSurface, size: 50)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "\$${vehicle.price.toStringAsFixed(0)}",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${vehicle.brand} ${vehicle.model}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.secondary),
                      onSelected: (value) => _handleAction(value, vehicle),
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(value: 'edit', child: Text("Edit")),
                          if (vehicle.status == 'active')
                            PopupMenuItem(value: 'mark_sold', child: Text("Mark as Sold")),
                           if (vehicle.status == 'sold')
                            PopupMenuItem(value: 'mark_active', child: Text("Mark as Active")),
                          PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                        ];
                      },
                    ),
                  ],
                ),
                Text("${vehicle.year} • ${vehicle.mileage} km", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat(Iconsax.eye, "${vehicle.viewsCount}"),
                    SizedBox(width: 16),
                    _buildStat(Iconsax.heart, "${vehicle.wishlistCount}"),
                    const Spacer(),
                    if (widget.status == 'active')
                       ElevatedButton(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehiclePage(vehicle: vehicle)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: Text("Edit"),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        SizedBox(width: 4),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
      ],
    );
  }
}
