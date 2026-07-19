import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/bento_card.dart';

/// Feature 5.1 - View Notifications.
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        ref.read(notificationProvider.notifier).load(userId);
      }
    });
  }

  Future<void> _refresh() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      await ref.read(notificationProvider.notifier).refresh(userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || item.isRead) return;
    try {
      await ref
          .read(notificationProvider.notifier)
          .markRead(item.notificationNumber, userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      await ref.read(notificationProvider.notifier).markAllRead(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications marked as read.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationProvider);
    final unreadCount =
        notificationsAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Notifications',
            breadcrumbs: ['Personal', 'Notifications'],
          );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  unreadCount > 0
                      ? 'You have $unreadCount unread notification${unreadCount == 1 ? '' : 's'}.'
                      : 'You are all caught up.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all read'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _messageCard(
                context,
                Icons.error_outline,
                'Could not load notifications',
                error.toString().replaceFirst('Exception: ', ''),
                onRetry: () {
                  final userId = ref.read(authProvider).user?.id;
                  if (userId != null) {
                    ref.read(notificationProvider.notifier).load(userId);
                  }
                },
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return _messageCard(
                    context,
                    Icons.notifications_none_outlined,
                    'No notifications yet',
                    'Updates about your requests, schedule, and important alerts will appear here.',
                    onRetry: _refresh,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _notificationTile(context, theme, notifications[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(
      BuildContext context, ThemeData theme, NotificationItem item) {
    final color = theme.colorScheme.primary;

    return BentoCard(
      onTap: item.isRead ? null : () => _markRead(item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isRead
                  ? Icons.notifications_none_outlined
                  : Icons.notifications_active_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              item.isRead ? FontWeight.w500 : FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTime(item.createdDate),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(
      BuildContext context, IconData icon, String title, String body,
      {VoidCallback? onRetry}) {
    final theme = Theme.of(context);
    return Center(
      child: BentoCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(local);
  }
}
