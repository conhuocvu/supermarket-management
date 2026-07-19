import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

/// Bell icon with an unread-count badge (Feature 5.1).
/// Tapping it opens a dropdown list of recent notifications in place;
/// "View all" navigates to the full notification screen.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final MenuController _menuController = MenuController();

  @override
  void initState() {
    super.initState();
    // Load once so the badge is correct even before the user ever
    // opens the dropdown.
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

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-280, 4),
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevation: const WidgetStatePropertyAll(8),
      ),
      menuChildren: [
        SizedBox(
          width: 340,
          child: _buildDropdownContent(context, notificationsAsync),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              // Refresh silently each time the dropdown opens
              final userId = ref.read(authProvider).user?.id;
              if (userId != null) {
                ref
                    .read(notificationProvider.notifier)
                    .refresh(userId)
                    .catchError((_) {});
              }
              controller.open();
            }
          },
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
      },
    );
  }

  Widget _buildDropdownContent(
    BuildContext context,
    AsyncValue<List<NotificationItem>> notificationsAsync,
  ) {
    final theme = Theme.of(context);
    final userId = ref.read(authProvider).user?.id;
    final items = notificationsAsync.valueOrNull ?? [];
    final unreadCount = items.where((n) => !n.isRead).length;
    final recent = items.take(6).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unreadCount > 0 && userId != null)
                TextButton(
                  onPressed: () {
                    ref
                        .read(notificationProvider.notifier)
                        .markAllRead(userId)
                        .catchError((_) {});
                  },
                  child: Text(
                    'Mark all read',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Body
        if (notificationsAsync.isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (notificationsAsync.hasError && items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to load notifications.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          )
        else if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.notifications_off_outlined,
                      size: 32, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No notifications yet.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final n in recent) _buildItem(context, n, userId),
                ],
              ),
            ),
          ),
        const Divider(height: 1),
        // Footer
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _menuController.close();
              context.go('/notifications');
            },
            child: Text(
              'View all notifications',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
      BuildContext context, NotificationItem n, String? userId) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        if (!n.isRead && userId != null) {
          ref
              .read(notificationProvider.notifier)
              .markRead(n.notificationNumber, userId)
              .catchError((_) {});
        }
      },
      child: Container(
        width: double.infinity,
        color: n.isRead
            ? null
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: n.isRead
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          n.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (n.createdDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(n.createdDate!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
