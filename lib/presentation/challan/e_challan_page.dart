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
        title: const Text("E-Challan"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
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
    if (user == null) return const Center(child: Text("Please login first"));

    // Query challans by ownerId — this always works regardless of vehicle service state
    return FutureBuilder<List<ChallanModel>>(
      future: Provider.of<ChallanService>(context, listen: false)
          .fetchOwnedChallans(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final challans = snapshot.data ?? [];

        if (challans.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.tick_circle,
            iconColor: AppColors.success,
            title: "No Challans! 🎉",
            subtitle:
                "Your vehicles have no pending e-challans.\n\nChallans appear here when a traffic officer\nissues one against your vehicle.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: challans.length,
            separatorBuilder: (_, idx) => const SizedBox(height: 12),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final challans = snapshot.data ?? [];

        if (challans.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.tick_circle,
            iconColor: AppColors.success,
            title: "No Challans",
            subtitle: "No pending challans found for\n$vehicleNumber",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challans.length,
          separatorBuilder: (_, idx) => const SizedBox(height: 12),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Iconsax.car, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Results for ${_vehicleNumberController.text}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text("Clear"),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchedChallans!.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildChallanCard(_searchedChallans![index]),
                  ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Info box explaining the feature ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.info_circle, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Search challans for any vehicle number.\n"
                    "If you own it, results load instantly.\n"
                    "For others' vehicles, an OTP is sent to the owner's email.",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Vehicle Number",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _vehicleNumberController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: "e.g. KA01AB1234",
              prefixIcon: Icon(Iconsax.car),
            ),
          ),
          const SizedBox(height: 20),
          if (_otpSent) ...[
            Text("OTP Verification",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              "Enter the OTP sent to the vehicle owner's email.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "6-digit OTP",
                prefixIcon: Icon(Iconsax.key),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: challanService.isLoading ? null : _verifyAccess,
              icon: challanService.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Iconsax.key, color: Colors.white, size: 16),
              label: Text(
                challanService.isLoading ? "Verifying…" : "Verify OTP",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _otpSent = false;
                _requestId = null;
                _otpController.clear();
              }),
              child: const Text("Cancel"),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: challanService.isLoading ? null : _requestAccess,
              icon: challanService.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Iconsax.search_normal, color: Colors.white, size: 16),
              label: Text(
                challanService.isLoading ? "Searching…" : "Search Challans",
                style: const TextStyle(color: Colors.white),
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
          .showSnackBar(const SnackBar(content: Text("Enter a vehicle number")));
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
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
        ? AppColors.success
        : isDisputed
            ? Colors.orange
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
          color: isPaid
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: violation + status chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.receipt_1, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challan.violationType,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      challan.vehicleNumber,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // ── Fine amount + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fine Amount",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
                  const Text("Issued On",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(
                    DateFormat('dd MMM yyyy').format(challan.issuedAt),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(challan),
                icon: const Icon(Iconsax.wallet_2, size: 16, color: Colors.white),
                label: const Text("Pay Now", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
        title: const Text("Pay Challan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.wallet_2, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              "₹${challan.fineAmount.toStringAsFixed(0)}",
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: AppColors.error),
            ),
            const SizedBox(height: 4),
            Text(challan.violationType,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment gateway integration coming soon!"),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text("Proceed to Pay",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
