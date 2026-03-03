import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:carvia/presentation/vehicle/vehicle_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:carvia/core/services/location_service.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/presentation/home/map_location_picker.dart';
import 'package:carvia/presentation/home/notifications_page.dart';
import 'package:carvia/presentation/home/vehicle_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter States
  String _selectedBrand = "All";
  String _selectedType = "All"; 
  RangeValues _priceRange = const RangeValues(0, 5000000);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: 20),
              _buildSearchBar(),
              SizedBox(height: 20),
              _buildSectionHeader("Popular Brands", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleListPage(title: "All Vehicles")));
              }),
              SizedBox(height: 10),
              _buildBrandsList(),
              SizedBox(height: 20),
              _buildSectionHeader("Featured Deals", () {
                _navigateToSeeAll("Featured Deals", (v) => _featuredCountFor(v.length));
              }),
              SizedBox(height: 10),
              _buildFeaturedCarousel(),
              SizedBox(height: 20),
              _buildSectionHeader("Recommended for You", () {
                _navigateToSeeAll("Recommended For You", (v) => 0, skipFeatured: true);
              }),
              SizedBox(height: 10),
              _buildRecommendedList(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSeeAll(String title, int Function(List<VehicleModel>) getCount, {bool skipFeatured = false}) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleListPage(title: title)));
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            radius: 20,
            child: ClipOval(child: Image.asset('assets/images/logo.jpg', width: 40, height: 40, fit: BoxFit.cover)),
          ),
        ),
        Column(
          children: [
            Text("LOCATION", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary, fontSize: 10, letterSpacing: 1.2)),
            Consumer<LocationService>(
              builder: (context, locationService, child) {
                return GestureDetector(
                  onTap: () => _showLocationPicker(context),
                  child: Row(
                    children: [
                      Icon(Iconsax.location5, size: 16, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 4),
                      Text(locationService.currentLocation, style: TextStyle(fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down, size: 16),
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
            child: Icon(Iconsax.notification, color: Theme.of(context).colorScheme.onSurface),
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
          ),
        ),
        const SizedBox(width: 10),
        _HoverIconBtn(
          icon: Iconsax.setting_4,
          onTap: _showFilterBottomSheet,
          tooltip: "Filters",
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: Text("SEE ALL", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12))),
      ],
    );
  }

  Widget _buildBrandsList() {
    final brands = [
      {"name": "All", "icon": Icons.grid_view},
      {"name": "Toyota", "icon": Icons.directions_car},
      {"name": "Tata", "icon": Icons.local_shipping},
      {"name": "Hyundai", "icon": Icons.drive_eta},
      {"name": "Maruti Suzuki", "icon": Icons.car_rental},
      {"name": "TVS", "icon": Icons.two_wheeler},
      {"name": "Royal Enfield", "icon": Icons.motorcycle},
      {"name": "Bajaj", "icon": Icons.electric_bike},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final brandName = brands[index]["name"] as String;
          final isSelected = _selectedBrand == brandName;
          return _HoverBrandChip(
            brandName: brandName,
            icon: brands[index]["icon"] as IconData,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedBrand = brandName);
              _applyFilters();
            },
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
          return SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
           return Container(
             height: 250,
             width: double.infinity,
             alignment: Alignment.center,
             decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
             child: Center(child: Text("No vehicles found")),
           );
        }

        final vehicles = _filterVehicles(snapshot.data!);
        final featuredCount = _featuredCountFor(vehicles.length);
        final featured = vehicles.take(featuredCount).toList();

        if (featured.isEmpty) {
           return SizedBox(
             height: 250,
             child: Center(child: Text("No featured vehicles matching filters")),
           );
        }

        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (context, index) => SizedBox(width: 16),
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
      
      // Brand Filter - Case insensitive matching
      if (_selectedBrand != "All") {
        vehicles = vehicles.where((v) => v.brand.toLowerCase() == _selectedBrand.toLowerCase()).toList();
      }
      
      // Type Filter - Case insensitive matching
      if (_selectedType != "All") {
        vehicles = vehicles.where((v) => v.type.toLowerCase() == _selectedType.toLowerCase()).toList();
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
      
      // Location Filter - Only apply if location is explicitly set and not "Current Location"
      // Apply AFTER other filters to be less restrictive
      final locationService = Provider.of<LocationService>(context, listen: false);
      final currentLocation = locationService.currentLocation;
      
      if (currentLocation != "Current Location" && currentLocation.isNotEmpty) {
        vehicles = vehicles.where((v) {
          // Always show vehicles without location data
          if (v.location.isEmpty) return true;
          // Show if location matches
          return v.location.toLowerCase().contains(currentLocation.toLowerCase()) || 
                 currentLocation.toLowerCase().contains(v.location.toLowerCase());
        }).toList();
      }

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
    return _FeaturedCard(vehicle: vehicle);
  }

  Widget _buildRecommendedList() {
    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No recommendations yet"));
        }

        final vehicles = _filterVehicles(snapshot.data!);
        final featuredCount = _featuredCountFor(vehicles.length);
        final recommended = vehicles.skip(featuredCount).toList();

        if (recommended.isEmpty) {
           if (vehicles.isNotEmpty) {
             return Center(child: Text("Check out our featured deals above!"));
           }
           return Center(child: Text("No recommendations matching filters"));
        }

        return Column(
          children: recommended.map((v) => Column(
            children: [
              _buildRecommendedCard(v),
              SizedBox(height: 10),
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 80,
                height: 80,
                child: vehicle.images.isNotEmpty 
                    ? VehicleImage(src: vehicle.images.first, fit: BoxFit.cover, width: 80, height: 80)
                    : Container(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        child: Icon(Icons.electric_car, color: Theme.of(context).colorScheme.onSurface),
                      ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${vehicle.brand} ${vehicle.model}", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${vehicle.year} • ${vehicle.fuel} • ${vehicle.mileage} mi", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(vehicle.displayPrice, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Consumer<VehicleService>(
              builder: (context, service, _) {
                 final isWishlisted = service.isInWishlist(vehicle.id);
                 return IconButton(
                   icon: Icon(
                      isWishlisted ? Iconsax.heart5 : Iconsax.heart, 
                      color: isWishlisted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface
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
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Location", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.map, color: Theme.of(context).colorScheme.primary),
                title: Text("Select on Map"),
                subtitle: Text("Pick precise location from Google Maps"),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const MapLocationPicker())
                  );
                  if (result != null && result is String) {
                    locationService.setLocation(result);
                    setState(() {}); // Trigger filter update
                  }
                },
              ),
              Divider(),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Iconsax.search_normal),
                  hintText: "Search city manually...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    locationService.setLocation(value);
                    Navigator.pop(context);
                    setState(() {}); // Trigger filter update
                  }
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                title: Text("Use Current Location"),
                onTap: () {
                  locationService.setLocation("Current Location"); 
                  Navigator.pop(context);
                  setState(() {}); // Trigger filter update
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
              padding: EdgeInsets.all(20),
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
                              _priceRange = const RangeValues(0, 5000000);
                              _selectedType = "All";
                            });
                          }, 
                          child: Text("Reset All")
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("Vehicle Type", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["All", "Car", "Bike"].map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setModalState(() => _selectedType = type);
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onSurface : null),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text("Brand", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["All", "Toyota", "Tata", "Hyundai", "Maruti Suzuki", "TVS", "Royal Enfield", "Bajaj"].map((brand) {
                        final isSelected = _selectedBrand == brand;
                        return ChoiceChip(
                          label: Text(brand),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setModalState(() => _selectedBrand = brand);
                          },
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onSurface : null),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text("Price Range: ₹${(_priceRange.start.toInt() / 100000).toStringAsFixed(1)}L - ₹${(_priceRange.end.toInt() / 100000).toStringAsFixed(1)}L", style: TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000000,
                      divisions: 50,
                      activeColor: Theme.of(context).colorScheme.primary,
                      labels: RangeLabels("₹${(_priceRange.start.toInt() / 100000).toStringAsFixed(1)}L", "₹${(_priceRange.end.toInt() / 100000).toStringAsFixed(1)}L"),
                      onChanged: (values) {
                        setModalState(() => _priceRange = values);
                      },
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                           _applyFilters(); // Apply filters
                           Navigator.pop(context);
                        },
                        child: Text("Apply Filters"),
                      ),
                    ),
                    SizedBox(height: 20),
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

// ---------------------------------------------------------------------------
// Hover-aware brand chip
// ---------------------------------------------------------------------------
class _HoverBrandChip extends StatefulWidget {
  final String brandName;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverBrandChip({
    required this.brandName,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HoverBrandChip> createState() => _HoverBrandChipState();
}

class _HoverBrandChipState extends State<_HoverBrandChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).cardColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final bool active = widget.isSelected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && !widget.isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? onSurface
                      : _hovered
                          ? primary.withValues(alpha: 0.12)
                          : cardColor,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.isSelected
                      ? surfaceColor
                      : _hovered
                          ? primary
                          : onSurface,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? primary : onSurface,
                ),
                child: Text(widget.brandName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hover-aware icon button for the filter
// ---------------------------------------------------------------------------
class _HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _HoverIconBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  State<_HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<_HoverIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    Widget btn = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hovered
                  ? primary.withValues(alpha: 0.12)
                  : onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.icon,
                key: ValueKey(_hovered),
                color: _hovered ? primary : onSurface,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// A featured vehicle card with a hover/press-activated dark overlay that
/// slides up from the bottom, showing the vehicle name clearly in white text.
class _FeaturedCard extends StatefulWidget {
  final VehicleModel vehicle;
  const _FeaturedCard({required this.vehicle});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) {
          setState(() => _isHovered = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailPage(vehicle: vehicle),
            ),
          );
        },
        onTapCancel: () => setState(() => _isHovered = false),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Vehicle Photo ──────────────────────────────────
                SizedBox(
                  width: 300,
                  height: 250,
                  child: vehicle.images.isNotEmpty
                      ? VehicleImage(
                          src: vehicle.images.first,
                          fit: BoxFit.cover,
                          width: 300,
                          height: 250,
                        )
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.05),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.electric_car,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 42,
                          ),
                        ),
                ),

                // ── Slide-up dark overlay with vehicle info ────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: _isHovered ? 100 : 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: _isHovered
                            ? [
                                Colors.black.withOpacity(0.88),
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ]
                            : [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.15),
                                Colors.transparent,
                              ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${vehicle.brand} ${vehicle.model}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 6,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vehicle.displayPrice,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_isHovered) ...[
                            const SizedBox(height: 4),
                            Text(
                              "${vehicle.year} • ${vehicle.fuel}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
