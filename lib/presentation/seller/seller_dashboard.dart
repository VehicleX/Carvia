import 'package:carvia/core/models/order_model.dart';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerDashboard extends StatelessWidget {
  final Function(int)? onTabChange;
  const SellerDashboard({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // ── Greeting Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        backgroundImage: user.profileImage != null
                            ? NetworkImage(user.profileImage!)
                            : null,
                        child: user.profileImage == null
                            ? const Icon(Iconsax.shop, color: Colors.white, size: 26)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back 👋",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              user.name,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Iconsax.shop, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text("Seller", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Your dealership at a glance",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
          ),

          // ── Stats Grid ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<VehicleModel>>(
              stream: Provider.of<VehicleService>(context, listen: false)
                  .getSellerVehiclesStream(user.uid),
              builder: (context, vehicleSnap) {
                return StreamBuilder<List<OrderModel>>(
                  stream: Provider.of<OrderService>(context, listen: false)
                      .getSellerOrdersStream(user.uid),
                  builder: (context, orderSnap) {
                    final vehicles = vehicleSnap.data ?? [];
                    final orders = orderSnap.data ?? [];

                    final activeCount = vehicles.where((v) => v.status == 'active').length;
                    final soldCount = vehicles.where((v) => v.status == 'sold').length;
                    final totalViews = vehicles.fold(0, (s, v) => s + v.viewsCount);
                    final pendingOrders =
                        orders.where((o) => o.status == OrderStatus.pending).length;
                    final confirmedOrders =
                        orders.where((o) => o.status == OrderStatus.confirmed).length;
                    final totalRevenue = vehicles
                        .where((v) => v.status == 'sold')
                        .fold(0.0, (s, v) => s + v.price);

                    final stats = [
                      _Stat("Active Listings", "$activeCount", Iconsax.car, Colors.blue, 1),
                      _Stat("Sold Vehicles", "$soldCount", Iconsax.tick_circle, Colors.green, 1),
                      _Stat("Pending Orders", "$pendingOrders", Iconsax.box, Colors.orange, 3),
                      _Stat("Total Views", "$totalViews", Iconsax.eye, Colors.purple, 5),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Overview",
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(
                                "Updated now",
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: stats.length,
                          itemBuilder: (ctx, i) => _StatCard(
                                stat: stats[i],
                                onTap: () => onTabChange?.call(stats[i].tabIndex),
                              ).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.15),
                        ),

                        // ── Revenue Banner ──────────────────────────────
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _RevenueBanner(
                            revenue: totalRevenue,
                            pending: pendingOrders + confirmedOrders,
                          ),
                        ).animate().fadeIn(delay: 350.ms),
                      ],
                    );
                  },
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
                      style:
                          GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Iconsax.add_circle,
                          label: "Add Vehicle",
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Iconsax.box,
                          label: "View Orders",
                          color: Colors.orange,
                          onTap: () => onTabChange?.call(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Iconsax.chart_2,
                          label: "Analytics",
                          color: Colors.purple,
                          onTap: () => onTabChange?.call(5),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
                ],
              ),
            ),
          ),

          // ── Recent Orders Preview ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Orders",
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () => onTabChange?.call(3),
                        child: const Text("See All"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<OrderModel>>(
            stream: Provider.of<OrderService>(context, listen: false)
                .getSellerOrdersStream(user.uid),
            builder: (context, snapshot) {
              final orders = (snapshot.data ?? []).take(3).toList();

              if (orders.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Iconsax.box, color: AppColors.textMuted),
                          SizedBox(width: 12),
                          Text("No orders yet",
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _MiniOrderCard(order: orders[i]),
                  ),
                  childCount: orders.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────
class _Stat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int tabIndex;
  const _Stat(this.title, this.value, this.icon, this.color, this.tabIndex);
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _Stat stat;
  final VoidCallback? onTap;
  const _StatCard({required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                        fontSize: 26, fontWeight: FontWeight.bold, color: stat.color)),
                Text(stat.title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Revenue Banner ────────────────────────────────────────────────────────────
class _RevenueBanner extends StatelessWidget {
  final double revenue;
  final int pending;
  const _RevenueBanner({required this.revenue, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Earnings",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  "₹${NumberFormat.compact().format(revenue)}",
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                if (pending > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$pending orders awaiting action",
                      style: const TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Iconsax.wallet_2, color: Colors.white24, size: 48),
        ],
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
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

// ── Mini Order Card (Dashboard preview) ───────────────────────────────────────
class _MiniOrderCard extends StatelessWidget {
  final OrderModel order;
  const _MiniOrderCard({required this.order});

  Color get _color {
    switch (order.status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.delivered: return AppColors.success;
      case OrderStatus.cancelled: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.car, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.vehicleName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  "₹${order.amount.toStringAsFixed(0)} • ${DateFormat('dd MMM').format(order.date)}",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
