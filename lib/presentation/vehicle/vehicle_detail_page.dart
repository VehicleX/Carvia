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
import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/presentation/ai/ai_chat_page.dart';

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
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Consumer<VehicleService>(
                builder: (context, vehicleService, child) {
                  final isWishlisted = vehicleService.isInWishlist(widget.vehicle.id);
                  return InkWell(
                    onTap: () {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      if (authService.currentUser != null) {
                        vehicleService.toggleWishlist(authService.currentUser!.uid, widget.vehicle.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please login to wishlist vehicles!")),
                        );
                      }
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red[200] : Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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
    return Container(
      height: 400,
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.vehicle.images.isNotEmpty ? widget.vehicle.images.length : 1,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              if (widget.vehicle.images.isEmpty) {
                return Container(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), 
                  child: Center(
                    child: Icon(Icons.directions_car, size: 80, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54))
                  )
                );
              }
              return Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: VehicleImage(
                  src: widget.vehicle.images[index], 
                  fit: BoxFit.contain,
                ),
              );
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
                    Text(widget.vehicle.displayPrice, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Text("Price", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openAIChat,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.magic_star, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Carvia AI Analysis",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface)),
                    Text("Tap for AI Recommendation Engine →",
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to AI Chat and pre-fill a query about this specific vehicle.
  void _openAIChat() {
    final aiService = Provider.of<AIService>(context, listen: false);
    final query = "Give me a detailed AI analysis and recommendation for the ${widget.vehicle.year} ${widget.vehicle.brand} ${widget.vehicle.model}. Include pros, cons, value for money and who should buy it.";
    // Send the message so when chat opens it already has context
    aiService.sendMessage(query);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatPage()),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Compare ─────────────────────────────────────
          _BottomBarButton(
            onTap: () {
              final compareService = Provider.of<CompareService>(context, listen: false);
              compareService.addToCompare(widget.vehicle);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePage()));
            },
            tooltip: "Compare",
            child: const Icon(Icons.compare_arrows_rounded, size: 22),
            outlined: true,
            fixedWidth: 56,
          ),
          const SizedBox(width: 10),
          // ── Test Drive ──────────────────────────────────
          Expanded(
            child: _BottomBarButton(
              onTap: _showBookTestDriveDialog,
              label: "Test Drive",
              outlined: true,
            ),
          ),
          const SizedBox(width: 10),
          // ── Buy Now ─────────────────────────────────────
          Expanded(
            flex: 2,
            child: _BottomBarButton(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutPage(vehicle: widget.vehicle)),
              ),
              label: "BUY NOW",
              filled: true,
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

// ---------------------------------------------------------------------------
// Reusable hover-aware bottom bar button
// ---------------------------------------------------------------------------
class _BottomBarButton extends StatefulWidget {
  final VoidCallback onTap;
  final String? label;
  final Widget? child;
  final bool outlined;
  final bool filled;
  final double? fixedWidth;
  final String? tooltip;

  const _BottomBarButton({
    required this.onTap,
    this.label,
    this.child,
    this.outlined = false,
    this.filled = false,
    this.fixedWidth,
    this.tooltip,
  });

  @override
  State<_BottomBarButton> createState() => _BottomBarButtonState();
}

class _BottomBarButtonState extends State<_BottomBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final outline = Theme.of(context).colorScheme.outline;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final Color bgColor;
    final Color fgColor;
    final Border? border;

    if (widget.filled) {
      bgColor = _hovered ? primary.withValues(alpha: 0.85) : primary;
      fgColor = onPrimary;
      border = null;
    } else if (widget.outlined) {
      bgColor = _hovered
          ? primary.withValues(alpha: 0.08)
          : Colors.transparent;
      fgColor = _hovered ? primary : onSurface;
      border = Border.all(color: _hovered ? primary : outline, width: 1.5);
    } else {
      bgColor = Colors.transparent;
      fgColor = onSurface;
      border = null;
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 52,
      width: widget.fixedWidth,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: (widget.filled && _hovered)
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (h) => setState(() => _hovered = h),
          child: Center(
            child: widget.child != null
                ? IconTheme(data: IconThemeData(color: fgColor), child: widget.child!)
                : Text(
                    widget.label ?? '',
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: widget.filled ? 0.8 : 0,
                    ),
                  ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: content,
    );
  }
}
