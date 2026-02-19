import 'package:carvia/core/models/order_model.dart';
import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: StreamBuilder<List<OrderModel>>(
        stream: user.role == UserRole.seller
            ? Provider.of<OrderService>(context, listen: false).getSellerOrdersStream(user.uid)
            : Provider.of<OrderService>(context, listen: false).getMyOrdersStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found", style: TextStyle(color: Colors.grey)));
          }

          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.confirmed: statusColor = Colors.blue; break;
      case OrderStatus.delivered: statusColor = Colors.green; break;
      case OrderStatus.cancelled: statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM dd, yyyy').format(order.date),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(order.status.toString().split('.').last.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Iconsax.box, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "\$${order.amount.toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: () {}, child: const Text("Track Order")),
              TextButton(onPressed: () {}, child: const Text("Invoice")),
            ],
          ),
        ],
      ),
    );
  }
}
