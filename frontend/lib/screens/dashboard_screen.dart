import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/notification_item.dart';
import '../widgets/bento_card.dart';
import 'inventory_issue_form.dart';
import 'product_update_form.dart';
import 'leave_request_form.dart';
import 'schedule_request_form.dart';
import 'problem_products_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title with Switch Role Account Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${appState.currentUser.title} Dashboard',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  final role = appState.currentUser.role;
                  if (role == UserRole.associate) {
                    appState.setTabIndex(1); // Chuyển vào giao diện Product List
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Đã vào giao diện Nhân viên Bán hàng')),
                    );
                  } else {
                    // Với các role khác, tạm thời giữ ở Dashboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã tải dữ liệu theo role: ${appState.currentUser.title}')),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Vào Không Gian Làm Việc'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          _buildProfileCard(context, appState),
                          const SizedBox(height: 16),
                          _buildCheckInCard(context, appState),
                          const SizedBox(height: 16),
                          _buildQuickActions(context, appState),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildNotificationsCard(context, appState),
                          const SizedBox(height: 16),
                          _buildActivitiesCard(context, appState),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildProfileCard(context, appState),
                    const SizedBox(height: 16),
                    _buildCheckInCard(context, appState),
                    const SizedBox(height: 16),
                    _buildQuickActions(context, appState),
                    const SizedBox(height: 16),
                    _buildNotificationsCard(context, appState),
                    const SizedBox(height: 16),
                    _buildActivitiesCard(context, appState),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(appState.currentUser.imageUrl),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.currentUser.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  appState.currentUser.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Shift: ${appState.currentUser.nextShift}',
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
                appState.currentUser.workHoursThisWeek,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              Text(
                'Worked this week',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final role = appState.currentUser.role;
    final List<Widget> actions = [];

    switch (role) {
      case UserRole.manager:
        actions.addAll([
          _buildActionItem(
            context,
            icon: Icons.list_alt,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Product List',
            onTap: () => appState.setTabIndex(1),
          ),
          _buildActionItem(
            context,
            icon: Icons.rate_review_outlined,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Review Requests',
            onTap: () => appState.setTabIndex(2),
          ),
          _buildActionItem(
            context,
            icon: Icons.edit_calendar,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Work Schedules',
            onTap: () => appState.setTabIndex(3),
          ),
          _buildActionItem(
            context,
            icon: Icons.price_change_outlined,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Price Update',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductUpdateForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.warning_amber_rounded,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Problem Products',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProblemProductsScreen()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.time_to_leave,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Request Leave',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LeaveRequestForm()),
              );
            },
          ),
        ]);
        break;
      case UserRole.associate:
        actions.addAll([
          _buildActionItem(
            context,
            icon: Icons.list_alt,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Product List',
            onTap: () => appState.setTabIndex(1),
          ),
          _buildActionItem(
            context,
            icon: Icons.report_problem,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Report Issue',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InventoryIssueForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.edit_note,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Update Suggestion',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductUpdateForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.rule,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Report Status',
            onTap: () => appState.setTabIndex(2),
          ),
          _buildActionItem(
            context,
            icon: Icons.date_range,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Swap Shift',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScheduleRequestForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.time_to_leave,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Request Leave',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LeaveRequestForm()),
              );
            },
          ),
        ]);
        break;
      case UserRole.cashier:
        actions.addAll([
          _buildActionItem(
            context,
            icon: Icons.search,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Product Search',
            onTap: () => appState.setTabIndex(1),
          ),
          _buildActionItem(
            context,
            icon: Icons.receipt_long_outlined,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Register Issue',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InventoryIssueForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.request_quote_outlined,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Price Suggestion',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductUpdateForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.rule,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Report Status',
            onTap: () => appState.setTabIndex(2),
          ),
          _buildActionItem(
            context,
            icon: Icons.date_range,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Swap Shift',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScheduleRequestForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.time_to_leave,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Request Leave',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LeaveRequestForm()),
              );
            },
          ),
        ]);
        break;
      case UserRole.stockController:
        actions.addAll([
          _buildActionItem(
            context,
            icon: Icons.inventory_2_outlined,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Inventory Stock',
            onTap: () => appState.setTabIndex(1),
          ),
          _buildActionItem(
            context,
            icon: Icons.warning_amber_rounded,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Problem Products',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProblemProductsScreen()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.edit_note,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Request Restock',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductUpdateForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.rule,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Report Status',
            onTap: () => appState.setTabIndex(2),
          ),
          _buildActionItem(
            context,
            icon: Icons.date_range,
            color: theme.colorScheme.secondary,
            backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
            label: 'Swap Shift',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScheduleRequestForm()),
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.time_to_leave,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
            label: 'Request Leave',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LeaveRequestForm()),
              );
            },
          ),
        ]);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            role == UserRole.manager ? 'Management Actions' : 'Staff Actions',
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
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final unreadCount = appState.notifications.where((n) => !n.isRead).length;

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
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => appState.markAllNotificationsAsRead(),
                  child: Text(
                    'Mark read',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appState.notifications.take(3).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = appState.notifications[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notif.type, theme).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notif.type),
                        color: _getNotificationColor(notif.type, theme),
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
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notif.description,
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

  Widget _buildActivitiesCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity Today',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            context,
            time: '09:12 AM',
            title: 'Submitted Inventory Report',
            subtitle: 'Aisle 4 - Dairy Section',
            isFirst: true,
          ),
          _buildActivityItem(
            context,
            time: '08:45 AM',
            title: 'Viewed SKU-8821 Detail',
            subtitle: 'Checked pricing update',
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
                color: isFirst ? theme.colorScheme.primary : theme.colorScheme.outline,
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

  Widget _buildCheckInCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: appState.isCheckedIn 
                      ? Colors.green.withOpacity(0.1) 
                      : theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appState.isCheckedIn 
                        ? Colors.green.withOpacity(0.3) 
                        : theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appState.isCheckedIn ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color: appState.isCheckedIn ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appState.isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: appState.isCheckedIn ? Colors.green : Colors.grey,
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECK-IN TIME',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.checkInTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECK-OUT TIME',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.checkOutTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(appState.isCheckedIn ? Icons.logout : Icons.login),
              label: Text(appState.isCheckedIn ? 'Check-Out Shift' : 'Check-In Now'),
              style: FilledButton.styleFrom(
                backgroundColor: appState.isCheckedIn 
                    ? theme.colorScheme.error.withOpacity(0.9) 
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                appState.toggleCheckIn();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(appState.isCheckedIn 
                        ? 'Successfully Checked-In to Shift!' 
                        : 'Successfully Checked-Out of Shift!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: appState.isCheckedIn ? Colors.green : theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
