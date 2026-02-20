import 'package:carvia/core/models/notification_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/notification_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<NotificationService>(context, listen: false).fetchNotifications(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification, size: 80, color: AppColors.textMuted.withValues(alpha:0.5)),
                  const SizedBox(height: 16),
                  Text("No notifications yet", style: GoogleFonts.outfit(fontSize: 18, color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notificationService.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notification = notificationService.notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case 'order':
        iconColor = Colors.green;
        iconData = Iconsax.box;
        break;
      case 'offer':
      case 'price_drop':
        iconColor = Colors.orange;
        iconData = Iconsax.discount_shape;
        break;
      case 'test_drive_booked':
      case 'test_drive':
        iconColor = Colors.blue;
        iconData = Iconsax.car;
        break;
      case 'auth_verified':
        iconColor = Colors.purple;
        iconData = Iconsax.verify;
        break;
      case 'insurance_expiry':
        iconColor = Colors.red;
        iconData = Iconsax.shield_cross;
        break;
      case 'challan_access_request':
        iconColor = Colors.amber;
        iconData = Iconsax.lock;
        break;
      case 'credit_earned':
        iconColor = Colors.teal;
        iconData = Iconsax.wallet_2;
        break;
      default:
        iconColor = AppColors.primary;
        iconData = Iconsax.notification;
    }

    return GestureDetector(
      onTap: () {
        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user != null && !notification.isRead) {
          Provider.of<NotificationService>(context, listen: false).markAsRead(user.uid, notification.id);
        }
        
        // Navigation Logic
        if (notification.type == 'insurance_expiry' && notification.data != null) {
           // Navigate to Insurance Page for that vehicle?
           // For now, simpler to just go to Notifs or stay. 
           // Implementation specific to routing structure.
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Theme.of(context).cardColor.withValues(alpha:0.5) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead ? null : Border.all(color: iconColor.withValues(alpha:0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: notification.isRead ? AppColors.textMuted : null)),
                  const SizedBox(height: 4),
                  Text(notification.body, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                     // Handle Timestamp or Date
                    DateFormat('MMM d, h:mm a').format(notification.createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
               Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CircleAvatar(radius: 4, backgroundColor: iconColor),
              ),
          ],
        ),
      ),
    );
  }
}
