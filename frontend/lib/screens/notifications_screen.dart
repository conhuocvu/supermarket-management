import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/notification_item.dart';
import '../widgets/bento_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notifications Log',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          if (appState.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                appState.markAllNotificationsAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.')),
                );
              },
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: appState.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              itemCount: appState.notifications.length,
              itemBuilder: (context, index) {
                final notif = appState.notifications[index];
                final statusColor = _getNotificationColor(notif.type, theme);

                return BentoCard(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  backgroundColor: notif.isRead ? theme.cardColor : theme.colorScheme.primaryContainer.withOpacity(0.05),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notif.type),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _timeAgo(notif.timestamp),
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.schedule:
        return Icons.calendar_today;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.alert:
        return theme.colorScheme.error;
      case NotificationType.schedule:
        return theme.colorScheme.secondary;
      case NotificationType.info:
        return theme.colorScheme.primary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
