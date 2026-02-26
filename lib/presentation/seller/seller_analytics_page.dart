import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerAnalyticsPage extends StatelessWidget {
  const SellerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return Center(child: Text("Please login"));

    return StreamBuilder<List<VehicleModel>>(
      stream: Provider.of<VehicleService>(context, listen: false)
          .getSellerVehiclesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final vehicles = snapshot.data ?? [];
        final totalViews = vehicles.fold(0, (s, v) => s + v.viewsCount);
        final totalWishlists = vehicles.fold(0, (s, v) => s + v.wishlistCount);
        final activeListings = vehicles.where((v) => v.status == 'active').length;
        final soldVehicles = vehicles.where((v) => v.status == 'sold').length;
        final totalRevenue = vehicles
            .where((v) => v.status == 'sold')
            .fold(0.0, (s, v) => s + v.price);
        final conversionRate = vehicles.isEmpty
            ? 0.0
            : (soldVehicles / vehicles.length) * 100;

        return CustomScrollView(
          slivers: [
            // ── Revenue Header ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.wallet_2, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54), size: 18),
                          SizedBox(width: 8),
                          Text("Total Revenue",
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54), fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "₹${NumberFormat('#,##,##0').format(totalRevenue)}",
                        style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _MiniStat("Sold", "$soldVehicles", Theme.of(context).colorScheme.primary),
                          SizedBox(width: 12),
                          _MiniStat("Active", "$activeListings", Theme.of(context).colorScheme.primary),
                          SizedBox(width: 12),
                          _MiniStat("Rate", "${conversionRate.toStringAsFixed(1)}%", Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
              ),
            ),

            // ── Engagement Stats ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Engagement",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _EngagementCard(
                            label: "Total Views",
                            value: NumberFormat.compact().format(totalViews),
                            icon: Iconsax.eye,
                            color: Theme.of(context).colorScheme.onSurface,
                            subtitle: vehicles.isEmpty
                                ? "0 avg/vehicle"
                                : "${(totalViews / vehicles.length).toStringAsFixed(1)} avg/vehicle",
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _EngagementCard(
                            label: "Wishlists",
                            value: "$totalWishlists",
                            icon: Iconsax.heart,
                            color: Theme.of(context).colorScheme.onSurface,
                            subtitle: vehicles.isEmpty
                                ? "0 avg/vehicle"
                                : "${(totalWishlists / vehicles.length).toStringAsFixed(1)} avg/vehicle",
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),

                    // ── Performance Bars ─────────────────────────────────
                    Text("Inventory Breakdown",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 14),
                    _InventoryBreakdown(vehicles: vehicles),
                    SizedBox(height: 28),

                    // ── Top performing vehicles ──────────────────────────
                    Text("Top Performing",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            _buildTopVehicles(context, vehicles),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        );
      },
    );
  }

  Widget _buildTopVehicles(BuildContext context, List<VehicleModel> vehicles) {
    if (vehicles.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("No vehicles yet.",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ),
      );
    }

    final sorted = List<VehicleModel>.from(vehicles)
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final top = sorted.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _TopVehicleRow(rank: i + 1, vehicle: top[i]),
        ),
        childCount: top.length,
      ),
    );
  }
}

// ── Mini Stat inside revenue card ──────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
          SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Engagement Card ────────────────────────────────────────────────────────────
class _EngagementCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _EngagementCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
          SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 10, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ── Inventory Breakdown ────────────────────────────────────────────────────────
class _InventoryBreakdown extends StatelessWidget {
  final List<VehicleModel> vehicles;
  const _InventoryBreakdown({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Text("No inventory data.",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary));
    }

    final total = vehicles.length;
    final byStatus = <String, int>{};
    for (final v in vehicles) {
      byStatus[v.status] = (byStatus[v.status] ?? 0) + 1;
    }

    final segments = [
      ('Active', byStatus['active'] ?? 0, Theme.of(context).colorScheme.onSurface),
      ('Sold', byStatus['sold'] ?? 0, Theme.of(context).colorScheme.onSurface),
      ('Reserved', byStatus['reserved'] ?? 0, Theme.of(context).colorScheme.onSurface),
      ('Inactive', byStatus['inactive'] ?? 0, Theme.of(context).colorScheme.onSurface),
    ].where((s) => s.$2 > 0).toList();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: segments
                    .map((s) => Expanded(
                          flex: s.$2,
                          child: Container(color: s.$3),
                        ))
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: segments
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: s.$3, shape: BoxShape.circle)),
                        SizedBox(width: 6),
                        Text(
                            "${s.$1} (${((s.$2 / total) * 100).toStringAsFixed(0)}%)",
                            style: TextStyle(fontSize: 12)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Top Vehicle Row ────────────────────────────────────────────────────────────
class _TopVehicleRow extends StatelessWidget {
  final int rank;
  final VehicleModel vehicle;
  const _TopVehicleRow({required this.rank, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final rankColors = [Theme.of(context).colorScheme.onSurface, Theme.of(context).colorScheme.onSurface, Theme.of(context).colorScheme.onSurface, Theme.of(context).colorScheme.onSurface, Theme.of(context).colorScheme.onSurface];
    final rankColor = rankColors[rank - 1];

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: rank == 1
            ? Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text("#$rank",
                style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: vehicle.images.isNotEmpty
                ? VehicleImage(src: vehicle.images.first, width: 56, height: 40)
                : Container(
                    width: 56,
                    height: 40,
                    color: Theme.of(context).colorScheme.surface,
                    child: Icon(Iconsax.car, size: 20)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${vehicle.brand} ${vehicle.model}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  "₹${NumberFormat.compact().format(vehicle.price)} • ${vehicle.year}",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Iconsax.eye, size: 12, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(width: 3),
                  Text("${vehicle.viewsCount}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: vehicle.status == 'sold'
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vehicle.status.toUpperCase(),
                  style: TextStyle(
                      color: vehicle.status == 'sold' ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
