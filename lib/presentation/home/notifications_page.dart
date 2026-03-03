import 'package:carvia/core/models/notification_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/notification_service.dart';
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
        Provider.of<NotificationService>(context, listen: false)
            .fetchNotifications(user.uid);
      }
    });
  }

  String? get _uid =>
      Provider.of<AuthService>(context, listen: false).currentUser?.uid;

  void _deleteOne(NotificationModel n) {
    final uid = _uid;
    if (uid == null) return;
    Provider.of<NotificationService>(context, listen: false)
        .deleteNotification(uid, n.id);
  }

  void _clearAll() async {
    final uid = _uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.notification_bing,
                color: Theme.of(ctx).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text('Clear All Notifications'),
          ],
        ),
        content: const Text(
            'This will permanently delete all your notifications. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<NotificationService>(context, listen: false)
          .clearAllNotifications(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<NotificationService>(
            builder: (context, ns, _) {
              if (ns.notifications.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: const Text('Clear All',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400),
              );
            },
          ),
        ],
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
                  Icon(Iconsax.notification,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary)),
                  const SizedBox(height: 8),
                  Text('You\'re all caught up!',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.6),
                          fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notificationService.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notificationService.notifications[index];
              return _SwipableNotificationCard(
                notification: notification,
                onDismiss: () => _deleteOne(notification),
                onTap: () {
                  final uid = _uid;
                  if (uid != null && !notification.isRead) {
                    notificationService.markAsRead(uid, notification.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipable card — swipe left to delete, tap to mark read
// ---------------------------------------------------------------------------
class _SwipableNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _SwipableNotificationCard({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  (IconData, Color) _iconFor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (notification.type) {
      case 'order':
        return (Iconsax.box, Colors.blue);
      case 'offer':
      case 'price_drop':
        return (Iconsax.discount_shape, Colors.green);
      case 'test_drive_booked':
      case 'test_drive':
        return (Iconsax.car, Colors.orange);
      case 'auth_verified':
        return (Iconsax.verify, Colors.teal);
      case 'insurance_expiry':
        return (Iconsax.shield_cross, Colors.red);
      case 'challan_access_request':
        return (Iconsax.lock, Colors.purple);
      case 'credit_earned':
        return (Iconsax.wallet_2, Colors.amber);
      default:
        return (Iconsax.notification, primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor) = _iconFor(context);
    final isRead = notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? null
                : Border.all(color: iconColor.withValues(alpha: 0.35)),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, h:mm a')
                              .format(notification.createdAt),
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.7),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unread dot + delete icon column
              Column(
                children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 2, left: 6),
                      decoration: BoxDecoration(
                          color: iconColor, shape: BoxShape.circle),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(Icons.close_rounded,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
