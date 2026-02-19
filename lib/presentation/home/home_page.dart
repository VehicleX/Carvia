import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:carvia/core/services/location_service.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/presentation/home/map_location_picker.dart';
import 'package:carvia/presentation/home/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter States
  String _selectedBrand = "All";
  String _selectedType = "All"; // Added Type State
  RangeValues _priceRange = const RangeValues(0, 300000);

  @override
  void initState() {
    super.initState();
    // No need to fetch manually, StreamBuilder handles it.
  }

  void _applyFilters() {
    setState(() {}); // This rebuilds the widget tree, re-running the filter logic inside StreamBuilders
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
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
          },
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: const Icon(Iconsax.notification),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search premium cars...",
              prefixIcon: const Icon(Iconsax.search_normal),
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showFilterBottomSheet,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.setting_4, color: Colors.white),
          ),
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
      {"name": "All", "icon": Icons.grid_view},
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
          final brandName = brands[index]["name"] as String;
          final isSelected = _selectedBrand == brandName;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedBrand = brandName);
              _applyFilters();
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    brands[index]["icon"] as IconData, 
                    size: 30,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(brandName, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
           return Container(
             height: 250,
             width: double.infinity,
             alignment: Alignment.center,
             decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
             child: const Center(child: Text("No vehicles found")),
           );
        }

        final vehicles = _filterVehicles(snapshot.data!);
        final featuredCount = _featuredCountFor(vehicles.length);
        final featured = vehicles.take(featuredCount).toList();

        if (featured.isEmpty) {
           return Container(
             height: 250,
             child: const Center(child: Text("No featured vehicles matching filters")),
           );
        }

        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildFeaturedCard(featured[index]);
            },
          ),
        );
      },
    );
  }

  // Filter Logic Helper
  List<VehicleModel> _filterVehicles(List<VehicleModel> allVehicles) {
      var vehicles = allVehicles;
      
      // Brand Filter
      if (_selectedBrand != "All") {
        vehicles = vehicles.where((v) => v.brand == _selectedBrand).toList();
      }
      
      // Type Filter
      if (_selectedType != "All") {
        vehicles = vehicles.where((v) => v.type == _selectedType).toList();
      }

      // Search Filter
      final query = _searchController.text.toLowerCase().trim();
      if (query.isNotEmpty) {
        vehicles = vehicles.where((v) => 
          v.brand.toLowerCase().contains(query) || 
          v.model.toLowerCase().contains(query)
        ).toList();
      }

      // Price Filter
      vehicles = vehicles.where((v) => v.price >= _priceRange.start && v.price <= _priceRange.end).toList();

      return vehicles;
  }

  int _featuredCountFor(int total) {
    if (total <= 0) return 0;
    if (total == 1) return 1;

    int count = (total / 2).ceil();
    if (count > 5) count = 5;
    if (count >= total) count = total - 1;
    return count;
  }

  Widget _buildFeaturedCard(VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
      },
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: vehicle.images.isNotEmpty
                  ? Image.network(
                      vehicle.images.first,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey,
                        alignment: Alignment.center,
                        child: const Icon(Icons.error, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: Colors.grey,
                      alignment: Alignment.center,
                      child: const Icon(Icons.electric_car, color: Colors.white, size: 42),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${vehicle.brand} ${vehicle.model}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            "${vehicle.year} • ${vehicle.fuel}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "\$${vehicle.price.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedList() {
    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No recommendations yet"));
        }

        final vehicles = _filterVehicles(snapshot.data!);
        final featuredCount = _featuredCountFor(vehicles.length);
        final recommended = vehicles.skip(featuredCount).toList();

        if (recommended.isEmpty) {
           if (vehicles.isNotEmpty) {
             return const Center(child: Text("Check out our featured deals above!"));
           }
           return const Center(child: Text("No recommendations matching filters"));
        }

        return Column(
          children: recommended.map((v) => Column(
            children: [
              _buildRecommendedCard(v),
              const SizedBox(height: 10),
            ],
          )).toList(),
        );
      }
    );
  }

  Widget _buildRecommendedCard(VehicleModel vehicle) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailPage(vehicle: vehicle)));
      },
      child: Container(
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
            Consumer<VehicleService>(
              builder: (context, service, _) {
                 final isWishlisted = service.isInWishlist(vehicle.id);
                 return IconButton(
                   icon: Icon(
                      isWishlisted ? Iconsax.heart5 : Iconsax.heart, 
                      color: isWishlisted ? Colors.red : AppColors.textMuted
                   ),
                   onPressed: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      if (authService.currentUser != null) {
                        await service.toggleWishlist(authService.currentUser!.uid, vehicle.id);
                      }
                   },
                 );
              }
            ),
          ],
        ),
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
              ListTile(
                leading: const Icon(Icons.map, color: AppColors.primary),
                title: const Text("Select on Map"),
                subtitle: const Text("Pick precise location from Google Maps"),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const MapLocationPicker())
                  );
                  if (result != null && result is String) {
                    locationService.setLocation(result);
                  }
                },
              ),
              const Divider(),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.search_normal),
                  hintText: "Search city manually...",
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
              ListTile(
                leading: const Icon(Icons.my_location, color: AppColors.primary),
                title: const Text("Use Current Location"),
                onTap: () {
                  locationService.setLocation("Current Location"); 
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Filters", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedBrand = "All";
                              _priceRange = const RangeValues(0, 300000);
                              // Reset logic for other filters would go here
                            });
                          }, 
                          child: const Text("Reset")
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Vehicle Type", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["All", "Car", "Bike", "Truck", "Auto"].map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setModalState(() => _selectedType = type);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text("Brand", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["All", "Tesla", "BMW", "Porsche", "Mercedes", "Toyota", "Honda"].map((brand) {
                        final isSelected = _selectedBrand == brand;
                        return ChoiceChip(
                          label: Text(brand),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setModalState(() => _selectedBrand = brand);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text("Price Range: \$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 300000,
                      divisions: 30,
                      activeColor: AppColors.primary,
                      labels: RangeLabels("\$${_priceRange.start.toInt()}", "\$${_priceRange.end.toInt()}"),
                      onChanged: (values) {
                        setModalState(() => _priceRange = values);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Fuel Type", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["All", "Petrol", "Diesel", "Electric", "Hybrid"].map((fuel) {
                         // Logic for Fuel Filter state management would be here
                         // For now, visual only as I need to update state variables in HomePage
                         return ChoiceChip(label: Text(fuel), selected: false, onSelected: (v){}); 
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                           _applyFilters(); // Apply filters
                           Navigator.pop(context);
                        },
                        child: const Text("Apply Filters"),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}
