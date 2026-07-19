import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/profile.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/bento_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _attendanceActionInProgress = false;

  String _workspacePath(int role) {
    switch (role) {
      case UserRoles.admin:
        return '/admin';
      case UserRoles.manager:
        return '/manager';
      case UserRoles.stockController:
        return '/stock';
      case UserRoles.salesAssociate:
        return '/sales';
      case UserRoles.cashier:
        return '/cashier';
      default:
        return '/dashboard';
    }
  }

  @override
  void initState() {
    super.initState();
    // Load today's attendance from the backend once the first frame is built
    // (auth state is already available at this point via the router guard).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        ref.read(attendanceProvider.notifier).loadTodayAttendance(userId);
        ref.read(notificationProvider.notifier).load(userId);
      }
    });
  }

  Future<void> _handleAttendanceAction(ThemeData theme, bool isCheckedIn) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _attendanceActionInProgress) return;

    setState(() => _attendanceActionInProgress = true);
    try {
      if (isCheckedIn) {
        await ref.read(attendanceProvider.notifier).checkOut(userId);
      } else {
        await ref.read(attendanceProvider.notifier).checkIn(userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckedIn
                ? 'Successfully Checked-Out of Shift!'
                : 'Successfully Checked-In to Shift!',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor:
              isCheckedIn ? theme.colorScheme.primary : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      // Re-sync with the backend in case local state drifted
      // (e.g. already checked in from another device).
      ref.read(attendanceProvider.notifier).loadTodayAttendance(userId);
    } finally {
      if (mounted) {
        setState(() => _attendanceActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final roleName = profile?.roleName ?? 'Staff';
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Home',
            breadcrumbs: ['Home', 'Dashboard'],
          );
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title with Enter Workspace Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$roleName Dashboard',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  final role = profile?.roleNumber ?? 0;
                  context.go(_workspacePath(role));
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Enter Workspace'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Responsive Grid Layout
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildProfileCard(context, authState.user?.email),
                          const SizedBox(height: 16),
                          _buildCheckInCard(context),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildNotificationsCard(context),
                          const SizedBox(height: 16),
                          _buildActivitiesCard(context),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildProfileCard(context, authState.user?.email),
                    const SizedBox(height: 16),
                    _buildCheckInCard(context),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 16),
                    _buildNotificationsCard(context),
                    const SizedBox(height: 16),
                    _buildActivitiesCard(context),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String? email) {
    final theme = Theme.of(context);
    final profile = ref.watch(authProvider).profile;
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (email ?? 'User');
    final initials = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    final status = (profile?.status ?? 'ACTIVE').toUpperCase();
    final memberSince = profile != null
        ? DateFormat('MMM y').format(profile.createdAt)
        : '—';

    return BentoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    initials,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile?.roleName ?? 'Staff',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Status: $status',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                memberSince,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              Text('Member since', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(authProvider).profile;
    final role = profile?.roleNumber ?? 0;
    final List<Widget> actions = [];

    if (role == UserRoles.stockController) {
      actions.addAll([
        _buildActionItem(
          context,
          icon: Icons.dashboard_outlined,
          color: theme.colorScheme.primary,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          label: 'Inventory Dashboard',
          onTap: () => context.go('/stock'),
        ),
        _buildActionItem(
          context,
          icon: Icons.list_alt,
          color: theme.colorScheme.secondary,
          backgroundColor:
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
          label: 'Product List',
          onTap: () => context.go('/stock/products'),
        ),
        _buildActionItem(
          context,
          icon: Icons.category_outlined,
          color: theme.colorScheme.primary,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          label: 'Categories',
          onTap: () => context.go('/stock/categories'),
        ),
        _buildActionItem(
          context,
          icon: Icons.add_box_outlined,
          color: theme.colorScheme.secondary,
          backgroundColor:
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
          label: 'Add Product',
          onTap: () => context.go('/stock/products/add'),
        ),
        _buildActionItem(
          context,
          icon: Icons.person_outline,
          color: theme.colorScheme.primary,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          label: 'My Profile',
          onTap: () => context.go('/profile'),
        ),
        _buildActionItem(
          context,
          icon: Icons.lock_outline,
          color: theme.colorScheme.secondary,
          backgroundColor:
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
          label: 'Change Password',
          onTap: () => context.push('/change-password'),
        ),
      ]);
    } else {
      actions.addAll([
        _buildActionItem(
          context,
          icon: Icons.work_outline,
          color: theme.colorScheme.primary,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          label: 'My Workspace',
          onTap: () => context.go(_workspacePath(role)),
        ),
        _buildActionItem(
          context,
          icon: Icons.person_outline,
          color: theme.colorScheme.secondary,
          backgroundColor:
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
          label: 'My Profile',
          onTap: () => context.go('/profile'),
        ),
        _buildActionItem(
          context,
          icon: Icons.lock_outline,
          color: theme.colorScheme.primary,
          backgroundColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          label: 'Change Password',
          onTap: () => context.push('/change-password'),
        ),
        _buildActionItem(
          context,
          icon: Icons.logout,
          color: theme.colorScheme.error,
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
          label: 'Sign Out',
          onTap: () => ref.read(authProvider.notifier).signOut(),
        ),
      ]);
    }

    final isManagement =
        role == UserRoles.admin || role == UserRoles.manager;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            isManagement ? 'Management Actions' : 'Staff Actions',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: actions,
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return BentoCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationProvider);
    final notifications = notificationsAsync.valueOrNull ?? [];
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        final userId = ref.read(authProvider).user?.id;
                        if (userId == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(notificationProvider.notifier)
                              .markAllRead(userId);
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e
                                  .toString()
                                  .replaceFirst('Exception: ', '')),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Mark read',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => context.go('/notifications'),
                    child: Text(
                      'View all',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (notificationsAsync.isLoading && notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notificationsAsync.hasError && notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Could not load notifications.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No notifications yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.take(3).length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notif.isRead
                              ? Icons.notifications_none_outlined
                              : Icons.notifications_active_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: notif.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notif.content,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivitiesCard(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final lastSignInRaw = authState.user?.lastSignInAt;
    final lastSignIn = lastSignInRaw != null
        ? DateFormat('hh:mm a')
            .format(DateTime.parse(lastSignInRaw).toLocal())
        : '—';
    final createdAt = authState.profile?.createdAt;
    final joined =
        createdAt != null ? DateFormat('MMM d').format(createdAt) : '—';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            context,
            time: lastSignIn,
            title: 'Signed in to your account',
            subtitle: 'Supermarket Management System',
            isFirst: true,
          ),
          _buildActivityItem(
            context,
            time: joined,
            title: 'Account created',
            subtitle: 'Profile initialized successfully',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String time,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isFirst
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInCard(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(attendanceProvider);

    final attendance = attendanceAsync.valueOrNull;
    final isLoading = attendanceAsync.isLoading;
    final isCheckedIn = attendance?.isCheckedIn ?? false;
    final checkInTime = attendance?.checkInTime != null
        ? DateFormat('hh:mm a').format(attendance!.checkInTime!.toLocal())
        : '--:--';
    final checkOutTime = attendance?.checkOutTime != null
        ? DateFormat('hh:mm a').format(attendance!.checkOutTime!.toLocal())
        : '--:--';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Attendance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCheckedIn
                        ? Colors.green.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color: isCheckedIn ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCheckedIn ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeBox(context, 'CHECK-IN TIME', checkInTime,
                    highlight: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _buildTimeBox(context, 'CHECK-OUT TIME', checkOutTime),
              ),
            ],
          ),
          if (attendanceAsync.hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not load attendance. Pull to refresh or try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _attendanceActionInProgress || isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(isCheckedIn ? Icons.logout : Icons.login),
              label: Text(isCheckedIn ? 'Check-Out Shift' : 'Check-In Now'),
              style: FilledButton.styleFrom(
                backgroundColor: isCheckedIn
                    ? theme.colorScheme.error.withValues(alpha: 0.9)
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _attendanceActionInProgress || isLoading
                  ? null
                  : () => _handleAttendanceAction(theme, isCheckedIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
