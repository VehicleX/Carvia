import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/presentation/police/police_challan_list_page.dart';
import 'package:carvia/presentation/police/police_issue_challan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleService>(context, listen: false).fetchSoldVehicles();
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      Provider.of<ChallanService>(context, listen: false).fetchDashboardStats(),
      Provider.of<VehicleService>(context, listen: false).fetchSoldVehicles(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: user.profileImage != null
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: user.profileImage == null
                            ? Icon(Iconsax.profile_circle,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 26)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Duty Active 👮",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                            Text(
                              user.name,
                              style: GoogleFonts.outfit(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.shield_tick,
                                size: 14,
                                color: Theme.of(context).colorScheme.surface),
                            const SizedBox(width: 4),
                            Text("Police Officer",
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.surface,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Station HQ: Sector 7G, Downtown Division",
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8),
                        fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
          ),

          // ── Dashboard Stats ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<ChallanService>(context, listen: false)
                  .fetchDashboardStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ??
                    {'total_issued': 0, 'revenue': 0.0, 'pending': 0};

                final statItems = [
                  _Stat("Total Issued", "${stats['total_issued']}", Iconsax.receipt,
                      Theme.of(context).colorScheme.primary),
                  _Stat("Revenue", "₹${(stats['revenue'] as double).toStringAsFixed(0)}",
                      Iconsax.money, Colors.green),
                  _Stat("Pending", "${stats['pending']}", Iconsax.timer,
                      Colors.orange),
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Performance Overview",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: statItems.length,
                      itemBuilder: (ctx, i) => _StatCard(stat: statItems[i])
                          .animate()
                          .fadeIn(delay: (i * 80).ms)
                          .slideY(begin: 0.15),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Quick Actions ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quick Actions",
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionWidget(
                          icon: Iconsax.receipt_add,
                          label: "Issue Challan",
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PoliceIssueChallan()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionWidget(
                          icon: Iconsax.receipt,
                          label: "My Issued",
                          color: Theme.of(context).colorScheme.onSurface,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PoliceChallanListPage()),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
                ],
              ),
            ),
          ),

          // ── Sold Vehicles Section ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Registered Vehicles",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () => Provider.of<VehicleService>(context, listen: false).fetchSoldVehicles(),
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSoldVehiclesList(context),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSoldVehiclesList(BuildContext context) {
    final vehicleService = Provider.of<VehicleService>(context);
    final vehicles = vehicleService.soldVehicles;

    if (vehicleService.isLoading && vehicles.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(Iconsax.car, size: 40, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text("No sold vehicles found.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final v = vehicles[index];
          final plate = (v.specs['licensePlate']?.toString().isNotEmpty == true) 
              ? v.specs['licensePlate'].toString().toUpperCase() 
              : "${v.brand} ${v.model}".toUpperCase();

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PoliceIssueChallan(prefilledVehicleNumber: plate),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      child: v.images.isNotEmpty
                          ? Image.network(v.images[0], fit: BoxFit.cover, width: double.infinity)
                          : Container(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              child: const Icon(Iconsax.car, size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: Text(
                            plate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.black,
                                letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${v.brand} ${v.model}",
                          style: TextStyle(
                              fontSize: 10, color: Theme.of(context).colorScheme.secondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Components ───────────────────────────────────────────────────────────────

class _Stat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.title, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stat.color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
              color: stat.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value,
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.bold, color: stat.color)),
              Text(stat.title,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionWidget(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
