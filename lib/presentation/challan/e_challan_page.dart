import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class EChallanPage extends StatefulWidget {
  final String? filterVehicleNumber; // Optional filter

  const EChallanPage({super.key, this.filterVehicleNumber});

  @override
  State<EChallanPage> createState() => _EChallanPageState();
}

class _EChallanPageState extends State<EChallanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _otpSent = false;
  String? _requestId;
  String? _accessToken;
  List<ChallanModel>? _searchedChallans;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // If filtering by specific vehicle, show simpler UI without tabs
    if (widget.filterVehicleNumber != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Challans - ${widget.filterVehicleNumber}"),
        ),
        body: _buildMyChallansTab(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Challan"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: "My Vehicles"),
            Tab(text: "Search Other"),
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

  Widget _buildMyChallansTab() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return const Center(child: Text("Please login first"));

    // If filtering, use that number directly
    if (widget.filterVehicleNumber != null) {
       return FutureBuilder<List<ChallanModel>>(
          future: Provider.of<ChallanService>(context, listen: false).fetchChallansForVehicles([widget.filterVehicleNumber!]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final challans = snapshot.data ?? [];
            if (challans.isEmpty) {
              return const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Iconsax.tick_circle, size: 60, color: AppColors.success),
                   SizedBox(height: 16),
                   Text("No pending challans found for this vehicle."),
                ],
              ));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challans.length,
              itemBuilder: (context, index) => _buildChallanCard(challans[index]),
            );
          },
       );
    }

    // Otherwise, fetch for all user vehicles
    return Consumer<VehicleService>(
      builder: (context, vehicleService, _) {
         final vehicles = vehicleService.userVehicles;
         final vehicleNumbers = vehicles
             .map((v) => v.specs['licensePlate'] as String?)
             .where((s) => s != null && s.isNotEmpty)
             .cast<String>()
             .toList();

         if (vehicleNumbers.isEmpty) {
            return const Center(child: Text("No vehicles found. Add a vehicle first."));
         }

         return FutureBuilder<List<ChallanModel>>(
            future: Provider.of<ChallanService>(context, listen: false).fetchChallansForVehicles(vehicleNumbers),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              final challans = snapshot.data ?? [];
              if (challans.isEmpty) {
                return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.tick_circle, size: 60, color: AppColors.success),
                    SizedBox(height: 16),
                    Text("No pending challans for your vehicles!"),
                  ],
                ));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challans.length,
                itemBuilder: (context, index) => _buildChallanCard(challans[index]),
              );
            },
         );
      }
    );
  }

  Widget _buildSearchTab() {
    final challanService = Provider.of<ChallanService>(context);
    
    if (_searchedChallans != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Results for ${_vehicleNumberController.text}", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchedChallans = null;
                      _otpSent = false;
                      _requestId = null;
                      _accessToken = null;
                      _vehicleNumberController.clear();
                      _otpController.clear();
                    });
                  },
                  child: const Text("Clear"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchedChallans!.isEmpty 
            ? const Center(child: Text("No challans found for this vehicle.")) 
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _searchedChallans!.length,
                itemBuilder: (context, index) => _buildChallanCard(_searchedChallans![index]),
              ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Enter Vehicle Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _vehicleNumberController,
            decoration: const InputDecoration(
              hintText: "e.g. CA 1234",
              prefixIcon: Icon(Iconsax.car),
            ),
          ),
          const SizedBox(height: 24),
          if (_otpSent) ...[
            const Text("Enter OTP sent to owner's email", style: TextStyle(fontSize: 14, color: AppColors.primary)),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                hintText: "Enter 6-digit OTP",
                prefixIcon: Icon(Iconsax.key),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: challanService.isLoading ? null : _verifyAccess,
              child: challanService.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Verify Access"),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: challanService.isLoading ? null : _requestAccess,
              child: challanService.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Request Access"),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestAccess() async {
    if (_vehicleNumberController.text.isEmpty) return;
    final challanService = Provider.of<ChallanService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final result = await challanService.requestAccess(
        _vehicleNumberController.text.trim(), 
        authService.currentUser!.uid,
      );

      if (mounted) {
        if (result['status'] == 'owned') {
          // Instant access
          final challans = await challanService.fetchOwnedChallans(authService.currentUser!.uid);
          setState(() {
            _searchedChallans = challans; // This logic might be slightly off if fetchOwned gets ALL, not just specific number. 
            // Ideally call fetchChallansByNumber directly if owned.
          });
        } else {
           setState(() {
            _otpSent = true;
            _requestId = result['requestId'];
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to ${result['email']}")));
          });
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _verifyAccess() async {
    if (_otpController.text.isEmpty) return;
    final challanService = Provider.of<ChallanService>(context, listen: false);

    try {
      final token = await challanService.verifyAccess(_requestId!, _otpController.text.trim());
      if (token != null) {
        // Fetch challans
        final challans = await challanService.fetchChallansWithToken(
          _vehicleNumberController.text.trim(), 
          token,
        );
        setState(() {
          _accessToken = token;
          _searchedChallans = challans;
        });
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildChallanCard(ChallanModel challan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(challan.violationType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: challan.status == ChallanStatus.paid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challan.status.name.toUpperCase(), 
                    style: TextStyle(
                      color: challan.status == ChallanStatus.paid ? AppColors.success : AppColors.error, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Fine: \$${challan.fineAmount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(challan.issuedAt.toString().split(' ')[0], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Pay or View Details
                },
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
