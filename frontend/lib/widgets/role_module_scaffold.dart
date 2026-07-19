import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class ModuleNavItem {
  final String label;
  final IconData icon;
  final String path;

  const ModuleNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
}

class RoleModuleScaffold extends ConsumerWidget {
  final String moduleLabel;
  final String title;
  final Widget body;
  final List<ModuleNavItem> navigationItems;
  final List<Widget> actions;

  const RoleModuleScaffold({
    super.key,
    required this.moduleLabel,
    required this.title,
    required this.body,
    required this.navigationItems,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final currentPath = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    Widget navigation() {
      return ColoredBox(
        color: const Color(0xFFF0F5F3),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moduleLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: navigationItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = navigationItems[index];
                    final active = currentPath == item.path ||
                        (item.path != '/manager' &&
                            item.path != '/cashier' &&
                            currentPath.startsWith('${item.path}/')) ||
                        (item.path == '/cashier/new-invoice' &&
                            (currentPath.startsWith('/cashier/pos/') ||
                                currentPath.startsWith('/cashier/checkout/') ||
                                currentPath.startsWith('/cashier/receipt/')));
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (!isDesktop) Navigator.of(context).pop();
                        context.go(item.path);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 21,
                              color: active
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: active
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.profile?.fullName ?? auth.user?.email ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                          Text(
                            auth.profile?.roleName ?? moduleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                      icon: Icon(
                        Icons.logout_rounded,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final content = Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: actions,
      ),
      drawer: isDesktop ? null : Drawer(child: navigation()),
      body: ColoredBox(
        color: const Color(0xFFF8F9FF),
        child: body,
      ),
    );

    if (!isDesktop) return content;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 260, child: navigation()),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

const managerNavigationItems = <ModuleNavItem>[
  ModuleNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    path: '/manager',
  ),
  ModuleNavItem(
    label: 'Staff Requests',
    icon: Icons.inbox_outlined,
    path: '/manager/requests',
  ),
  ModuleNavItem(
    label: 'Leave Requests',
    icon: Icons.event_available_outlined,
    path: '/manager/leave-requests',
  ),
  ModuleNavItem(
    label: 'Shift Changes',
    icon: Icons.swap_horiz_rounded,
    path: '/manager/shift-change-requests',
  ),
];

const cashierNavigationItems = <ModuleNavItem>[
  ModuleNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    path: '/cashier',
  ),
  ModuleNavItem(
    label: 'New Invoice',
    icon: Icons.receipt_long_outlined,
    path: '/cashier/new-invoice',
  ),
  ModuleNavItem(
    label: 'Shift Invoices',
    icon: Icons.history_rounded,
    path: '/cashier/invoices',
  ),
];
