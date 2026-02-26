import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
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
import 'package:carvia/presentation/vehicle/chat_page.dart';
import 'package:carvia/core/services/ai_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  int _currentImageIndex = 0;

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
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: BackButton(color: Theme.of(context).colorScheme.onSurface, onPressed: () => Navigator.pop(context)),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {},
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Consumer<VehicleService>(
              builder: (context, vehicleService, child) {
                final isWishlisted = vehicleService.isInWishlist(widget.vehicle.id);
                return IconButton(
                  icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface),
                  onPressed: () {
                    final authService = Provider.of<AuthService>(context, listen: false);
                     if (authService.currentUser != null) {
                        vehicleService.toggleWishlist(authService.currentUser!.uid, widget.vehicle.id);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please login to wishlist vehicles!")));
                     }
                  },
                );
              },
            ),
          ),
          SizedBox(width: 20),
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
                return Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), child: Center(child: Icon(Icons.directions_car, size: 80, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54))));
              }
              return VehicleImage(src: widget.vehicle.images[index], fit: BoxFit.cover);
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
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      padding: EdgeInsets.all(24),
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
                    Text("\$${widget.vehicle.price.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Text("Fixed Price", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                  ],
                ),
            ],
          ),
          SizedBox(height: 8),
          
          if (isOwnerOrExternal) ...[
             Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.vehicle.specs['licensePlate'] != null ? "Plate: ${widget.vehicle.specs['licensePlate']}" : "Your Vehicle",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)
              ),
             ),
          ] else ...[
             Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("Stock: #CV-992-01", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
             ),
          ],
          
          SizedBox(height: 24),
          _buildSpecGrid(),
          SizedBox(height: 24),
          
          // Hide AI and Seller for owners
          if (!isOwnerOrExternal) ...[
            _buildAIAnalysis(),
            SizedBox(height: 24),
          ],
          
          Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(
            // If external and no description, show generic owner text
            (widget.vehicle.isExternal && widget.vehicle.specs['description'] == null) 
                ? "Manage your vehicle details, insurance, and challans here."
                : (widget.vehicle.specs['description'] ?? "This is a masterpiece of engineering. One-owner, garage-kept, and maintained exclusively by certified technicians."),
            style: TextStyle(color: Theme.of(context).colorScheme.secondary, height: 1.5),
          ),
          SizedBox(height: 24),
          
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 10)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.magic_star, color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Carvia AI Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("98% Match for your preferences", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: _showAIAnalysis, child: Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  void _showAIAnalysis() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.magic_star, color: Theme.of(context).colorScheme.onSurface, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text("AI Analysis", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 20),
              FutureBuilder<String>(
                future: Provider.of<AIService>(context, listen: false).generateVehicleAIAnalysis(widget.vehicle),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error generating analysis."));
                  }
                  return Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        snapshot.data ?? "",
                        style: TextStyle(height: 1.5, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
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
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/32.jpg"),
                radius: 25,
              ),
              SizedBox(width: 16),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.onSurface),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Iconsax.call, size: 14, color: Theme.of(context).colorScheme.secondary),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            contactText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final user = Provider.of<AuthService>(context, listen: false).currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login to chat')));
                    return;
                  }
                  if (user.uid == widget.vehicle.sellerId) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This is your own listing')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
                    currentUserId: user.uid,
                    currentUserName: user.name,
                    otherUserId: widget.vehicle.sellerId,
                    otherUserName: sellerName,
                    vehicleId: widget.vehicle.id,
                    vehicleName: '${widget.vehicle.brand} ${widget.vehicle.model}',
                  )));
                },
                icon: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.message, size: 20)),
              ),
              SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final number = sellerPhone.isNotEmpty ? sellerPhone : 'Not available';
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          Icon(Iconsax.call, color: Theme.of(context).colorScheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Seller Contact'),
                        ],
                      ),
                      content: Text(
                        number,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10)), child: Icon(Iconsax.call, size: 20)),
              ),
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
         padding: EdgeInsets.all(20),
         decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1), blurRadius: 10, offset: Offset(0, -5))],
         ),
         child: Row(
           children: [
             Expanded(
               child: ElevatedButton.icon(
                 onPressed: () {
                   // Navigate to service history or maintenance (Future feature)
                 },
                 icon: Icon(Iconsax.setting_2),
                 label: Text("Manage Vehicle"),
                 style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
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
         padding: EdgeInsets.all(20),
         decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1), blurRadius: 10, offset: Offset(0, -5))],
         ),
         child: Center(child: Text("You own this vehicle", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
       );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
               final compareService = Provider.of<CompareService>(context, listen: false);
               compareService.addToCompare(widget.vehicle);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePage()));
            },
            icon: Icon(Icons.compare_arrows),
            tooltip: "Compare",
            style: IconButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.all(12),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showBookTestDriveDialog(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Test Drive", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(vehicle: widget.vehicle)));
              },
              child: Text("BUY NOW"),
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
