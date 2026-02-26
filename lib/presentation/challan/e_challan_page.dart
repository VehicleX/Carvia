import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EChallanPage extends StatefulWidget {
  final String? filterVehicleNumber; // Optional filter from My Vehicles card

  const EChallanPage({super.key, this.filterVehicleNumber});

  @override
  State<EChallanPage> createState() => _EChallanPageState();
}

class _EChallanPageState extends State<EChallanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  String? _requestId;
  List<ChallanModel>? _searchedChallans;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vehicleNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If filtering by a specific plate from My Vehicles page
    if (widget.filterVehicleNumber != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Challans – ${widget.filterVehicleNumber}"),
          centerTitle: true,
        ),
        body: _buildFilteredView(widget.filterVehicleNumber!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("E-Challan"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.outline,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          tabs: [
            Tab(icon: Icon(Iconsax.car, size: 16), text: "My Challans"),
            Tab(icon: Icon(Iconsax.search_normal, size: 16), text: "Search Vehicle"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyChallansTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  // ── My Challans Tab ───────────────────────────────────────────────────────
  Widget _buildMyChallansTab() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return Center(child: Text("Please login first"));

    // Query challans by ownerId — this always works regardless of vehicle service state
    return FutureBuilder<List<ChallanModel>>(
      future: Provider.of<ChallanService>(context, listen: false)
          .fetchOwnedChallans(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final challans = snapshot.data ?? [];

        if (challans.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.tick_circle,
            iconColor: Theme.of(context).colorScheme.onSurface,
            title: "No Challans! 🎉",
            subtitle:
                "Your vehicles have no pending e-challans.\n\nChallans appear here when a traffic officer\nissues one against your vehicle.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: challans.length,
            separatorBuilder: (_, idx) => SizedBox(height: 12),
            itemBuilder: (context, index) => _buildChallanCard(challans[index]),
          ),
        );
      },
    );
  }

  // ── Filtered View (from My Vehicles → Challans button) ───────────────────
  Widget _buildFilteredView(String vehicleNumber) {
    return FutureBuilder<List<ChallanModel>>(
      future: Provider.of<ChallanService>(context, listen: false)
          .fetchChallansForVehicles([vehicleNumber]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final challans = snapshot.data ?? [];

        if (challans.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.tick_circle,
            iconColor: Theme.of(context).colorScheme.onSurface,
            title: "No Challans",
            subtitle: "No pending challans found for\n$vehicleNumber",
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: challans.length,
          separatorBuilder: (_, idx) => SizedBox(height: 12),
          itemBuilder: (context, index) => _buildChallanCard(challans[index]),
        );
      },
    );
  }

  // ── Search Tab ────────────────────────────────────────────────────────────
  Widget _buildSearchTab() {
    final challanService = Provider.of<ChallanService>(context);

    if (_searchedChallans != null) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Iconsax.car, color: Theme.of(context).colorScheme.primary, size: 16),
                SizedBox(width: 8),
                Text(
                  "Results for ${_vehicleNumberController.text}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _searchedChallans = null;
                    _otpSent = false;
                    _requestId = null;
                    _vehicleNumberController.clear();
                    _otpController.clear();
                  }),
                  icon: Icon(Icons.close_rounded, size: 14),
                  label: Text("Clear"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchedChallans!.isEmpty
                ? _buildEmptyState(
                    icon: Iconsax.search_normal,
                    title: "No Challans Found",
                    subtitle: "No challans found for this vehicle number.",
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _searchedChallans!.length,
                    separatorBuilder: (_, idx) => SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildChallanCard(_searchedChallans![index]),
                  ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Info box explaining the feature ──
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle, color: Theme.of(context).colorScheme.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Search challans for any vehicle number.\n"
                    "If you own it, results load instantly.\n"
                    "For others' vehicles, an OTP is sent to the owner's email.",
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text("Vehicle Number",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          TextField(
            controller: _vehicleNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: "e.g. KA01AB1234",
              prefixIcon: Icon(Iconsax.car),
            ),
          ),
          SizedBox(height: 20),
          if (_otpSent) ...[
            Text("OTP Verification",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text(
              "Enter the OTP sent to the vehicle owner's email.",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "6-digit OTP",
                prefixIcon: Icon(Iconsax.key),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: challanService.isLoading ? null : _verifyAccess,
              icon: challanService.isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary, strokeWidth: 2))
                  : Icon(Iconsax.key, color: Theme.of(context).colorScheme.onSurface, size: 16),
              label: Text(
                challanService.isLoading ? "Verifying…" : "Verify OTP",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _otpSent = false;
                _requestId = null;
                _otpController.clear();
              }),
              child: Text("Cancel"),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: challanService.isLoading ? null : _requestAccess,
              icon: challanService.isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary, strokeWidth: 2))
                  : Icon(Iconsax.search_normal, color: Theme.of(context).colorScheme.onSurface, size: 16),
              label: Text(
                challanService.isLoading ? "Searching…" : "Search Challans",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _requestAccess() async {
    final number = _vehicleNumberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter a vehicle number")));
      return;
    }
    final challanService = Provider.of<ChallanService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final result = await challanService.requestAccess(number, authService.currentUser!.uid);

      if (!mounted) return;

      if (result['status'] == 'owned') {
        // Instant access for own vehicle
        final challans = await challanService.fetchChallansForVehicles([number]);
        if (mounted) setState(() => _searchedChallans = challans);
      } else {
        setState(() {
          _otpSent = true;
          _requestId = result['requestId'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("OTP sent to ${result['email']}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _verifyAccess() async {
    if (_otpController.text.isEmpty) return;
    final challanService = Provider.of<ChallanService>(context, listen: false);

    try {
      final token = await challanService.verifyAccess(_requestId!, _otpController.text.trim());
      if (token != null && mounted) {
        final challans = await challanService.fetchChallansWithToken(
            _vehicleNumberController.text.trim(), token);
        if (mounted) setState(() => _searchedChallans = challans);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: iconColor ?? Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallanCard(ChallanModel challan) {
    final isPaid = challan.status == ChallanStatus.paid;
    final isDisputed = challan.status == ChallanStatus.disputed;
    final statusColor = isPaid
        ? Theme.of(context).colorScheme.onSurface
        : isDisputed
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
        border: Border.all(
          color: isPaid
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: violation + status chip
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.receipt_1, color: statusColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challan.violationType,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      challan.vehicleNumber,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  challan.status.name.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1),
          SizedBox(height: 12),
          // ── Fine amount + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fine Amount",
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11)),
                  Text(
                    "₹${challan.fineAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: statusColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Issued On",
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11)),
                  Text(
                    DateFormat('dd MMM yyyy').format(challan.issuedAt),
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          if (!isPaid) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(challan),
                icon: Icon(Iconsax.wallet_2, size: 16, color: Theme.of(context).colorScheme.onSurface),
                label: Text("Pay Now", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(ChallanModel challan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Pay Challan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.wallet_2, size: 48, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 12),
            Text(
              "₹${challan.fineAmount.toStringAsFixed(0)}",
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 4),
            Text(challan.violationType,
                style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Payment gateway integration coming soon!"),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              );
            },
            child: Text("Proceed to Pay",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
