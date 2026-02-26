import 'package:carvia/core/models/order_model.dart';

import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    final isSeller = user.role == UserRole.seller;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSeller ? "Seller Orders" : "My Orders"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: isSeller
            ? Provider.of<OrderService>(context, listen: false).getSellerOrdersStream(user.uid)
            : Provider.of<OrderService>(context, listen: false).getMyOrdersStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.box, size: 80, color: Theme.of(context).colorScheme.secondary),
                  SizedBox(height: 16),
                  Text(
                    isSeller ? "No customer orders yet" : "You haven't ordered anything yet",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, idx) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order, isSeller: isSeller, currentUserId: user.uid);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isSeller;
  final String currentUserId;

  const _OrderCard({required this.order, required this.isSeller, required this.currentUserId});

  Color _statusColor(BuildContext context, OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return Theme.of(context).colorScheme.onSurface;
      case OrderStatus.delivered: return Theme.of(context).colorScheme.onSurface;
      case OrderStatus.cancelled: return Theme.of(context).colorScheme.onSurface;
      default: return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return Iconsax.tick_circle;
      case OrderStatus.delivered: return Iconsax.box_tick;
      case OrderStatus.cancelled: return Iconsax.close_circle;
      default: return Iconsax.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, order.status);
    final statusLabel = order.status.toString().split('.').last.toUpperCase();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: date + status chip
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 14, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(order.date),
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(order.status), size: 12, color: color),
                    SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
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
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text(
                      "\$${order.amount.toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (order.creditsEarned > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.star, size: 13, color: Theme.of(context).colorScheme.onSurface),
                      SizedBox(width: 3),
                      Text("+${order.creditsEarned} cr",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 14),
          Divider(height: 1),
          SizedBox(height: 10),
          // ── Action buttons
          Row(
            children: [
              // Track Order (buyer) / Confirm Order (seller pending)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTrackingDialog(context),
                  icon: Icon(Iconsax.location, size: 14),
                  label: Text("Track Order", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Seller: Mark Delivered (only on confirmed orders)
              if (isSeller && order.status == OrderStatus.confirmed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelivery(context),
                    icon: Icon(Iconsax.box_tick, size: 14, color: Theme.of(context).colorScheme.onSurface),
                    label: Text("Mark Delivered",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              // Seller: Confirm Order (pending orders)
              if (isSeller && order.status == OrderStatus.pending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmOrder(context),
                    icon: Icon(Iconsax.tick_circle, size: 14, color: Theme.of(context).colorScheme.onSurface),
                    label: Text("Confirm",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTrackingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _OrderTrackingDialog(order: order),
    );
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Order?"),
        content: Text("Confirm ${order.vehicleName} order from the buyer?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
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
            SnackBar(content: Text("Order confirmed! ✅"), backgroundColor: Theme.of(context).colorScheme.surface),
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

  Future<void> _confirmDelivery(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Mark as Delivered?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Confirm delivery of ${order.vehicleName} to the buyer?"),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.star, color: Theme.of(context).colorScheme.onSurface, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Buyer will receive 50 bonus credits on delivery!",
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Deliver", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🚗 Order marked delivered! Buyer earned 50 credits."),
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
}

// ── Order Tracking Dialog ─────────────────────────────────────────────────────

class _OrderTrackingDialog extends StatelessWidget {
  final OrderModel order;
  const _OrderTrackingDialog({required this.order});

  int get _currentStep {
    switch (order.status) {
      case OrderStatus.pending: return 0;
      case OrderStatus.confirmed: return 1;
      case OrderStatus.delivered: return 3;
      case OrderStatus.cancelled: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TrackStep(icon: Iconsax.receipt_1, label: "Order Placed",
          desc: DateFormat('MMM dd, hh:mm a').format(order.date)),
      _TrackStep(icon: Iconsax.tick_circle, label: "Confirmed by Seller",
          desc: "Seller has confirmed your order"),
      _TrackStep(icon: Iconsax.truck, label: "Out for Delivery",
          desc: "Vehicle is on its way to you"),
      _TrackStep(icon: Iconsax.box_tick, label: "Delivered",
          desc: order.status == OrderStatus.delivered ? "Your vehicle has arrived! 🎉" : "Waiting for delivery"),
    ];

    final current = _currentStep;

    if (order.status == OrderStatus.cancelled) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Order Cancelled"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.close_circle, color: Theme.of(context).colorScheme.primary, size: 60),
            SizedBox(height: 12),
            Text("Your order for ${order.vehicleName} was cancelled."),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.location, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Track Order", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(order.vehicleName,
                style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
            SizedBox(height: 20),
            ...List.generate(steps.length, (i) {
              final step = steps[i];
              final isDone = i <= current;
              final isActive = i == current;
              final isLast = i == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: icon + vertical line
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? (isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          border: isActive
                              ? Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), width: 2)
                              : null,
                        ),
                        child: Icon(
                          step.icon,
                          size: 16,
                          color: isDone ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: i < current
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  // ── Right: text
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.label,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: isDone ? null : Theme.of(context).colorScheme.onSurface,
                              )),
                          SizedBox(height: 2),
                          Text(step.desc,
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TrackStep {
  final IconData icon;
  final String label;
  final String desc;
  const _TrackStep({required this.icon, required this.label, required this.desc});
}
