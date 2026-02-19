import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:carvia/presentation/vehicle/compare_page.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/presentation/vehicle/checkout_page.dart';
import 'package:carvia/presentation/vehicle/book_test_drive_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  int _currentImageIndex = 0;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    // Increment view count when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleService>(context, listen: false).incrementVehicleView(widget.vehicle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: CircleAvatar(
          backgroundColor: Colors.black45,
          child: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.black45,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.black45,
            child: Consumer<VehicleService>(
              builder: (context, vehicleService, child) {
                final isWishlisted = vehicleService.isInWishlist(widget.vehicle.id);
                return IconButton(
                  icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.red : Colors.white),
                  onPressed: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                     if (authService.currentUser != null) {
                        vehicleService.toggleWishlist(authService.currentUser!.uid, widget.vehicle.id);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to wishlist vehicles!")));
                     }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(),
            _buildContent(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageSlider() {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.vehicle.images.isNotEmpty ? widget.vehicle.images.length : 1,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              if (widget.vehicle.images.isEmpty) {
                return Container(color: Colors.grey.shade900, child: const Center(child: Icon(Icons.directions_car, size: 80, color: Colors.white54)));
              }
              return Image.network(widget.vehicle.images[index], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error));
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.vehicle.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? AppColors.primary : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isOwnerOrExternal = widget.vehicle.isExternal || (user != null && widget.vehicle.sellerId == user.uid);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${widget.vehicle.year} ${widget.vehicle.brand} ${widget.vehicle.model}",
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              if (!isOwnerOrExternal)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("\$${widget.vehicle.price.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text("Fixed Price", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (isOwnerOrExternal) ...[
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.vehicle.specs['licensePlate'] != null ? "Plate: ${widget.vehicle.specs['licensePlate']}" : "Your Vehicle",
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)
              ),
             ),
          ] else ...[
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Stock: #CV-992-01", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
             ),
          ],
          
          const SizedBox(height: 24),
          _buildSpecGrid(),
          const SizedBox(height: 24),
          
          // Hide AI and Seller for owners
          if (!isOwnerOrExternal) ...[
            _buildAIAnalysis(),
            const SizedBox(height: 24),
          ],
          
          const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            // If external and no description, show generic owner text
            (widget.vehicle.isExternal && widget.vehicle.specs['description'] == null) 
                ? "Manage your vehicle details, insurance, and challans here."
                : (widget.vehicle.specs['description'] ?? "This is a masterpiece of engineering. One-owner, garage-kept, and maintained exclusively by certified technicians."),
            style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          if (!isOwnerOrExternal)
            _buildSellerCard(),
        ],
      ),
    );
  }

  Widget _buildSpecGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildSpecItem(Icons.local_gas_station, "Fuel Type", widget.vehicle.fuel),
        _buildSpecItem(Icons.settings_input_component, "Transmission", widget.vehicle.transmission),
        _buildSpecItem(Icons.calendar_today, "Year", "${widget.vehicle.year}"),
        _buildSpecItem(Icons.speed, "Mileage", "${widget.vehicle.mileage} miles"),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.magic_star, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Carvia AI Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("98% Match for your preferences", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vehicle.sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        final sellerData = snapshot.data?.data() ?? <String, dynamic>{};
        final sellerName = (sellerData['name']?.toString().trim().isNotEmpty ?? false)
            ? sellerData['name'].toString()
            : ((widget.vehicle.specs['sellerName']?.toString().trim().isNotEmpty ?? false)
                ? widget.vehicle.specs['sellerName'].toString()
                : 'Verified Seller');

        final sellerPhone = (sellerData['phone']?.toString().trim().isNotEmpty ?? false)
            ? sellerData['phone'].toString()
            : (widget.vehicle.specs['sellerPhone']?.toString() ?? '');
        final sellerEmail = (sellerData['email']?.toString().trim().isNotEmpty ?? false)
            ? sellerData['email'].toString()
            : (widget.vehicle.specs['sellerEmail']?.toString() ?? '');

        final contactText = sellerPhone.isNotEmpty
            ? sellerPhone
            : (sellerEmail.isNotEmpty ? sellerEmail : 'Contact details unavailable');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/32.jpg"),
                radius: 25,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: AppColors.success),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Iconsax.call, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            contactText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.message, size: 20))),
              const SizedBox(width: 8),
              IconButton(onPressed: () {}, icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.call, size: 20))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    // If vehicle is external (manually added), don't show buy/test drive options
    if (widget.vehicle.isExternal) {
       return Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
         ),
         child: Row(
           children: [
             Expanded(
               child: ElevatedButton.icon(
                 onPressed: () {
                   // Navigate to service history or maintenance (Future feature)
                 },
                 icon: const Icon(Iconsax.setting_2),
                 label: const Text("Manage Vehicle"),
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
               ),
             ),
           ],
         ),
       );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isOwner = user != null && widget.vehicle.sellerId == user.uid;

    if (isOwner) {
       return Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
         ),
         child: const Center(child: Text("You own this vehicle", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
       );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
               final compareService = Provider.of<CompareService>(context, listen: false);
               compareService.toggleCompare(widget.vehicle);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePage()));
            },
            icon: const Icon(Icons.compare_arrows),
            tooltip: "Compare",
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showBookTestDriveDialog(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Test Drive", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(vehicle: widget.vehicle)));
              },
              child: const Text("BUY NOW"),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookTestDriveDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookTestDrivePage(vehicle: widget.vehicle),
      ),
    );
  }
}
