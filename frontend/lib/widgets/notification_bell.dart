import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

/// Bell icon with an unread-count badge (Feature 5.1).
/// Shown in the app header; tapping it opens the notification screen.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  @override
  void initState() {
    super.initState();
    // Load once so the badge is correct even before the user ever
    // opens the notification screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null &&
          ref.read(notificationProvider).valueOrNull == null) {
        ref.read(notificationProvider.notifier).load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationProvider);
    final unreadCount =
        notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.go('/notifications'),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
        child: Icon(
          unreadCount > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
