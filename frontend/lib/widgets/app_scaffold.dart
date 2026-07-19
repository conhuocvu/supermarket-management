import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const AppScaffold({super.key, required this.body, this.title, this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final currentPath = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path;

    final shellState = ref.watch(shellLayoutProvider);
    
    String displayTitle = title ?? shellState.title;
    List<String> displayBreadcrumbs = shellState.breadcrumbs;
    final displayActions = actions ?? shellState.actions;

    if (currentPath == '/manager/staff') {
      displayTitle = 'Staff Management';
      displayBreadcrumbs = ['Manager', 'Staff'];
    } else if (currentPath.startsWith('/manager/staff/') && currentPath != '/manager/staff') {
      displayTitle = 'Staff Details';
      displayBreadcrumbs = ['Manager', 'Staff', 'Details'];
    } else if (currentPath == '/manager/promotion') {
      displayTitle = 'Promotions';
      displayBreadcrumbs = ['Manager', 'Promotions'];
    }

    final authState = ref.watch(authProvider);
    final fullName =
        authState.profile?.fullName ??
        authState.user?.email ??
        'Inventory Staff';
    final roleName = authState.profile?.roleName ?? 'Warehouse Staff';

    final isManager = currentPath.startsWith('/manager');
    final sidebarWidth = isManager ? 220.0 : 256.0;

    final List<Map<String, dynamic>> menuItems = isManager
        ? [
            {
              'title': 'Dashboard',
              'icon': Icons.dashboard_rounded,
              'active': currentPath == '/manager',
            },
            {
              'title': 'Staff',
              'icon': Icons.people_alt_outlined,
              'active': currentPath.startsWith('/manager/staff'),
            },
            {
              'title': 'Requests',
              'icon': Icons.receipt_long_outlined,
              'active': currentPath.startsWith('/manager/requests'),
            },
            {
              'title': 'Promotion',
              'icon': Icons.campaign_outlined,
              'active': currentPath.startsWith('/manager/promotion'),
            },
            {
              'title': 'Supplier',
              'icon': Icons.local_shipping_outlined,
              'active': currentPath.startsWith('/manager/supplier'),
            },
            {
              'title': 'Reports',
              'icon': Icons.bar_chart_rounded,
              'active': currentPath.startsWith('/manager/reports'),
            },
          ]
        : [
            {
              'title': 'Dashboard',
              'icon': Icons.dashboard_outlined,
              'active': currentPath == '/stock',
            },
            {
              'title': 'Products',
              'icon': Icons.inventory_2_outlined,
              'active': currentPath.startsWith('/stock/products'),
            },
            {
              'title': 'Categories',
              'icon': Icons.category_outlined,
              'active': currentPath.startsWith('/stock/categories'),
            },
            {
              'title': 'Transactions',
              'icon': Icons.swap_horiz_outlined,
              'active': currentPath.startsWith('/stock/transactions'),
            },
            {
              'title': 'Purchase Requests',
              'icon': Icons.shopping_cart_outlined,
              'active': currentPath.startsWith('/stock/purchase-requests'),
            },
            {
              'title': 'Low Stock',
              'icon': Icons.priority_high_outlined,
              'active': currentPath.startsWith('/stock/low-stock'),
            },
            {
              'title': 'Expiring Products',
              'icon': Icons.event_busy_outlined,
              'active': false,
            },
            {
              'title': 'Product Reports',
              'icon': Icons.assessment_outlined,
              'active': false,
            },
          ];

    Widget buildSidebarContent() {
      return Container(
        color: const Color(0xFFEFF3FF), // surface-container-low
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isManager
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Viridian Ops',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          fullName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Store Manager',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supermarket Management',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
            isManager
                ? const Divider(color: Color(0xFFBFC9C3), height: 1)
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(),
                  ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isActive = item['active'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        if (!isDesktop) {
                          Navigator.pop(context);
                        }
                        if (isManager) {
                          if (item['title'] == 'Dashboard') {
                            context.go('/manager');
                          } else if (item['title'] == 'Staff') {
                            context.go('/manager/staff');
                          } else if (item['title'] == 'Requests') {
                            context.go('/manager/requests');
                          } else if (item['title'] == 'Promotion') {
                            context.go('/manager/promotion');
                          } else if (item['title'] == 'Supplier') {
                            context.go('/manager/supplier');
                          } else if (item['title'] == 'Reports') {
                            context.go('/manager/reports');
                          }
                        } else {
                          if (item['title'] == 'Dashboard') {
                            context.go('/stock');
                          } else if (item['title'] == 'Products') {
                            context.go('/stock/products');
                          } else if (item['title'] == 'Categories') {
                            context.go('/stock/categories');
                          } else if (item['title'] == 'Transactions') {
                            context.go('/stock/transactions');
                          } else if (item['title'] == 'Purchase Requests') {
                            context.go('/stock/purchase-requests');
                          } else if (item['title'] == 'Low Stock') {
                            context.go('/stock/low-stock');
                          }
                        }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isActive
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['title'] as String,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFFBFC9C3), height: 1),
            isManager
                ? InkWell(
                    onTap: () => ref.read(authProvider.notifier).signOut(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.person_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                roleName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Logout',
                          icon: Icon(
                            Icons.logout_outlined,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          onPressed: () =>
                              ref.read(authProvider.notifier).signOut(),
                        ),
                      ],
                    ),
                  ),
            if (isManager) const SizedBox(height: 8),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: Drawer(
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xFFBFC9C3), width: 1),
                    ),
                  ),
                  child: buildSidebarContent(),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFBFC9C3), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              displayTitle,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Row(children: displayActions),
                          ],
                        ),
                        if (shellState.subtitle != null && shellState.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            shellState.subtitle!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ] else if (displayBreadcrumbs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: displayBreadcrumbs
                                .asMap()
                                .entries
                                .map((entry) {
                                  final idx = entry.key;
                                  final label = entry.value;
                                  final isLast =
                                      idx == displayBreadcrumbs.length - 1;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isLast
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isLast
                                              ? theme.colorScheme.onSurface
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                      if (!isLast)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 14,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF8F9FF),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayTitle, style: theme.textTheme.titleLarge),
              if (shellState.subtitle != null && shellState.subtitle!.isNotEmpty)
                Text(
                  shellState.subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          actions: displayActions,
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
        ),
        drawer: Drawer(child: buildSidebarContent()),
        body: Column(
          children: [
            if (shellState.subtitle == null && displayBreadcrumbs.isNotEmpty)
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFBFC9C3), width: 0.5),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: displayBreadcrumbs.asMap().entries.map((
                      entry,
                    ) {
                      final idx = entry.key;
                      final label = entry.value;
                      final isLast = idx == displayBreadcrumbs.length - 1;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLast
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isLast
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            Expanded(
              child: Material(color: const Color(0xFFF8F9FF), child: body),
            ),
          ],
        ),
      );
    }
  }
}
