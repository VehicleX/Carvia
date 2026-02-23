
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("My Wishlist", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
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
          Icon(Iconsax.heart_slash, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text("Traffic is clear here!", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Start liking vehicles to build your dream garage.", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                vehicle.images.first,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 120, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 4),
                    Text(
                      "\$${vehicle.price.toStringAsFixed(0)}", 
                      style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Iconsax.gas_station, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(vehicle.fuel, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Icon(Iconsax.speedometer, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text("${vehicle.mileage} km", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Delete Action
            IconButton(
              icon: const Icon(Iconsax.heart5, color: AppColors.error),
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
