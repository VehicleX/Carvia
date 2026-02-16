import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:carvia/core/services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  void initState() {
    super.initState();
    // Fetch vehicles when home page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleService>(context, listen: false).fetchVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildSectionHeader("Popular Brands", () {}),
              const SizedBox(height: 10),
              _buildBrandsList(),
              const SizedBox(height: 20),
              _buildSectionHeader("Featured Deals", () {}),
              const SizedBox(height: 10),
              _buildFeaturedCarousel(),
              const SizedBox(height: 20),
              _buildSectionHeader("Recommended for You", () {}),
              const SizedBox(height: 10),
              _buildRecommendedList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).cardColor,
          child: IconButton(
            icon: const Icon(Iconsax.menu_1),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        Column(
          children: [
            Text("LOCATION", style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.2)),
            Consumer<LocationService>(
              builder: (context, locationService, child) {
                return GestureDetector(
                  onTap: () => _showLocationPicker(context),
                  child: Row(
                    children: [
                      const Icon(Iconsax.location5, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(locationService.currentLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: Theme.of(context).cardColor,
          child: const Icon(Iconsax.notification),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search premium cars...",
              prefixIcon: const Icon(Iconsax.search_normal),
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.setting_4, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: const Text("SEE ALL", style: TextStyle(color: AppColors.primary, fontSize: 12))),
      ],
    );
  }

  Widget _buildBrandsList() {
    final brands = [
      {"name": "Tesla", "icon": Icons.electric_car},
      {"name": "BMW", "icon": Icons.directions_car},
      {"name": "Porsche", "icon": Icons.speed},
      {"name": "Mercedes", "icon": Icons.stars},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(brands[index]["icon"] as IconData, size: 30),
              ),
              const SizedBox(height: 8),
              Text(brands[index]["name"] as String, style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return Consumer<VehicleService>(
      builder: (context, vehicleService, child) {
        if (vehicleService.isLoading) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        
        // Show empty state if no vehicles (or use placeholder for demo if requested, but instruction says no dummy data)
        // I will show a message if empty.
        if (vehicleService.featuredVehicles.isEmpty) {
           return Container(
             height: 250,
             width: double.infinity,
             alignment: Alignment.center,
             decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
             child: const Text("No featured vehicles available"),
           );
        }

        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vehicleService.featuredVehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildFeaturedCard(vehicleService.featuredVehicles[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedCard(VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
        // Navigate to details
        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
      },
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.grey, // Placeholder for image
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                // In real app, use Image.network(vehicle.images.first)
                child: vehicle.images.isNotEmpty 
                  ? Image.network(vehicle.images.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error))
                  : const Center(child: Icon(Icons.directions_car, size: 50, color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${vehicle.year} ${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 14, color: AppColors.textMuted),
                      Text(" ${vehicle.mileage} mi", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.settings, size: 14, color: AppColors.textMuted),
                      Text(" ${vehicle.transmission}", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${vehicle.price.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Details", style: TextStyle(fontSize: 12)),
                      ),
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

  Widget _buildRecommendedList() {
    return Consumer<VehicleService>(
      builder: (context, vehicleService, child) {
        if (vehicleService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vehicleService.recommendedVehicles.isEmpty) {
          return const Center(child: Text("No recommendations yet"));
        }

        return Column(
          children: vehicleService.recommendedVehicles.map((v) => Column(
            children: [
              _buildRecommendedCard(v),
              const SizedBox(height: 10),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _buildRecommendedCard(VehicleModel vehicle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: vehicle.images.isNotEmpty 
                ? Image.network(vehicle.images.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error))
                : const Icon(Icons.electric_car, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${vehicle.year} • ${vehicle.fuel} • ${vehicle.mileage} mi", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text("\$${vehicle.price.toStringAsFixed(0)}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final locationService = Provider.of<LocationService>(context, listen: false);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Location", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.search_normal),
                  hintText: "Search city...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    locationService.setLocation(value);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 20),
              Text("Recent Locations", style: GoogleFonts.outfit(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: locationService.recentLocations.map((loc) => ActionChip(
                  label: Text(loc),
                  onPressed: () {
                    locationService.setLocation(loc);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text("Use Current Location"),
                onTap: () {
                  locationService.setLocation("Current Location"); // In real app, use Geolocation
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
