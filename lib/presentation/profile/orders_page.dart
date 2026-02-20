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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.box, size: 80, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    isSeller ? "No customer orders yet" : "You haven't ordered anything yet",
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, idx) => const SizedBox(height: 12),
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

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      default: return Colors.orange;
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
    final color = _statusColor(order.status);
    final statusLabel = order.status.toString().split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: date + status chip
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(order.date),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(order.status), size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Vehicle info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.car, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.vehicleName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      "\$${order.amount.toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (order.creditsEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text("+${order.creditsEarned} cr",
                          style: const TextStyle(
                              color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // ── Action buttons
          Row(
            children: [
              // Track Order (buyer) / Confirm Order (seller pending)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTrackingDialog(context),
                  icon: const Icon(Iconsax.location, size: 14),
                  label: const Text("Track Order", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Seller: Mark Delivered (only on confirmed orders)
              if (isSeller && order.status == OrderStatus.confirmed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelivery(context),
                    icon: const Icon(Iconsax.box_tick, size: 14, color: Colors.white),
                    label: const Text("Mark Delivered",
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              // Seller: Confirm Order (pending orders)
              if (isSeller && order.status == OrderStatus.pending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmOrder(context),
                    icon: const Icon(Iconsax.tick_circle, size: 14, color: Colors.white),
                    label: const Text("Confirm",
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
        title: const Text("Confirm Order?"),
        content: Text("Confirm ${order.vehicleName} order from the buyer?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
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
            const SnackBar(content: Text("Order confirmed! ✅"), backgroundColor: Colors.blue),
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
        title: const Text("Mark as Delivered?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Confirm delivery of ${order.vehicleName} to the buyer?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.star, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Buyer will receive 50 bonus credits on delivery!",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deliver", style: TextStyle(color: Colors.white)),
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
            const SnackBar(
              content: Text("🚗 Order marked delivered! Buyer earned 50 credits."),
              backgroundColor: Colors.green,
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
        title: const Text("Order Cancelled"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.close_circle, color: Colors.red, size: 60),
            const SizedBox(height: 12),
            Text("Your order for ${order.vehicleName} was cancelled."),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.location, color: AppColors.primary),
                const SizedBox(width: 8),
                Text("Track Order", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(order.vehicleName,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
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
                              ? (isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2))
                              : Colors.grey.withValues(alpha: 0.15),
                          border: isActive
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          step.icon,
                          size: 16,
                          color: isDone ? AppColors.primary : Colors.grey,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: i < current
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // ── Right: text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.label,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: isDone ? null : AppColors.textMuted,
                              )),
                          const SizedBox(height: 2),
                          Text(step.desc,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
