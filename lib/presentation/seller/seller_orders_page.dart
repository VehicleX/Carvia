import 'package:carvia/core/models/order_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return Center(child: Text("Login required"));

    return StreamBuilder<List<OrderModel>>(
      stream: Provider.of<OrderService>(context, listen: false)
          .getSellerOrdersStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.box, size: 60, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 20),
                Text("No Orders Yet",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
                SizedBox(height: 8),
                Text(
                  "Orders from buyers will appear here.\nConfirm and deliver them to complete a sale.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, height: 1.5),
                ),
              ],
            ),
          );
        }

        // Split into pending/confirmed and delivered/other
        final active = orders
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.confirmed)
            .toList();
        final completed = orders
            .where((o) =>
                o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              if (active.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    "Action Required (${active.length})",
                    Theme.of(context).colorScheme.onSurface,
                    Iconsax.notification,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SellerOrderCard(order: active[i]),
                    childCount: active.length,
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    "Completed (${completed.length})",
                    Theme.of(context).colorScheme.onSurface,
                    Iconsax.tick_circle,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SellerOrderCard(order: completed[i]),
                    childCount: completed.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Seller Order Card ──────────────────────────────────────────────────────

class _SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  const _SellerOrderCard({required this.order});

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case OrderStatus.pending: return Theme.of(context).colorScheme.onSurface;
      case OrderStatus.confirmed: return Theme.of(context).colorScheme.onSurface;
      case OrderStatus.delivered: return Theme.of(context).colorScheme.onSurface;
      case OrderStatus.cancelled: return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData get _statusIcon {
    switch (order.status) {
      case OrderStatus.pending: return Iconsax.clock;
      case OrderStatus.confirmed: return Iconsax.tick_circle;
      case OrderStatus.delivered: return Iconsax.box_tick;
      case OrderStatus.cancelled: return Iconsax.close_circle;
    }
  }

  String get _statusLabel =>
      order.status.toString().split('.').last.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: date + status
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 12, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(order.date),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11),
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 11, color: color),
                    SizedBox(width: 4),
                    Text(_statusLabel,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // ── Vehicle info
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.car, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.vehicleName,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text(
                      "₹${order.amount.toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "₹${order.amount.toStringAsFixed(0)}",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1),
          SizedBox(height: 10),

          // ── Action buttons
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (order.status == OrderStatus.pending) {
      // Show CONFIRM button
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmOrder(context),
              icon: Icon(Iconsax.tick_circle, size: 16, color: Theme.of(context).colorScheme.onSurface),
              label: Text("Confirm Order",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _cancelOrder(context),
            icon: Icon(Iconsax.close_circle, size: 16, color: Theme.of(context).colorScheme.onSurface),
            label: Text("Cancel",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.confirmed) {
      // Show DELIVER button — this is the key action that moves car to buyer's My Vehicles
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.star, size: 14, color: Theme.of(context).colorScheme.onSurface),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Marking delivered will add this car to the buyer's My Vehicles and award them 50 credits.",
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deliverOrder(context),
              icon: Icon(Iconsax.box_tick, size: 16, color: Theme.of(context).colorScheme.onSurface),
              label: Text("Mark as Delivered",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // Delivered / Cancelled — no actions
    if (order.status == OrderStatus.delivered) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box_tick, color: Theme.of(context).colorScheme.onSurface, size: 16),
          SizedBox(width: 6),
          Text("Delivered — Car added to buyer's account",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.close_circle, color: Theme.of(context).colorScheme.onSurface, size: 16),
        SizedBox(width: 6),
        Text("Order Cancelled",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _confirmOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Confirm Order?"),
        content: Text(
            "Accept the order for ${order.vehicleName}?\n\nYou'll then need to mark it delivered once the vehicle is handed over."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Provider.of<OrderService>(context, listen: false)
            .updateOrderStatus(order.id, OrderStatus.confirmed);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Order confirmed! Now deliver the vehicle."),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Future<void> _deliverOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Mark as Delivered? 🚗"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirm vehicle handover to buyer for:\n\"${order.vehicleName}\""),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("This will instantly:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 8),
                  _BulletPoint("Add the car to buyer's My Vehicles"),
                  _BulletPoint("Award buyer 50 bonus credits"),
                  _BulletPoint("Send buyer a delivery notification"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Not Yet")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes, Deliver!",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );

      try {
        await Provider.of<OrderService>(context, listen: false).deliverOrder(
          orderId: order.id,
          buyerId: order.userId,
          sellerId: order.sellerId,
          vehicleId: order.vehicleId,
          vehicleName: order.vehicleName,
          deliveryCredits: 50,
        );
        if (context.mounted) {
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "🚗 Delivered! Car added to buyer's My Vehicles. +50 credits awarded."),
              backgroundColor: Theme.of(context).colorScheme.surface,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // close loader
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Cancel Order?"),
        content: Text(
            "This will cancel the buyer's order. This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Keep")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Cancel Order",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await Provider.of<OrderService>(context, listen: false)
            .updateOrderStatus(order.id, OrderStatus.cancelled);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Order cancelled."),
                backgroundColor: Theme.of(context).colorScheme.surface),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface),
          SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
