
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final vehicleService = Provider.of<VehicleService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    await vehicleService.initWishlist(authService.currentUser!.uid);
    final list = await vehicleService.fetchWishlistVehicles();
    
    if (mounted) {
      setState(() {
        _vehicles = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("My Wishlist", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty 
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.heart_slash, size: 64, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text("Traffic is clear here!", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Start liking vehicles to build your dream garage.", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _vehicles.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleDetailPage(vehicle: vehicle)));
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1),
          boxShadow: [
             BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              child: VehicleImage(
              src: vehicle.images.first,
              width: 120,
              height: 120,
            ),
            ),
            
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${vehicle.year} ${vehicle.brand} ${vehicle.model}",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "\$${vehicle.price.toStringAsFixed(0)}", 
                      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Iconsax.gas_station, size: 14, color: Theme.of(context).colorScheme.secondary),
                        SizedBox(width: 4),
                        Text(vehicle.fuel, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
                        SizedBox(width: 12),
                        Icon(Iconsax.speedometer, size: 14, color: Theme.of(context).colorScheme.secondary),
                        SizedBox(width: 4),
                        Text("${vehicle.mileage} km", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Delete Action
            IconButton(
              icon: Icon(Iconsax.heart5, color: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                 final vehicleService = Provider.of<VehicleService>(context, listen: false);
                 final authService = Provider.of<AuthService>(context, listen: false);
                 await vehicleService.toggleWishlist(authService.currentUser!.uid, vehicle.id);
                 _loadWishlist(); // Refresh
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}
