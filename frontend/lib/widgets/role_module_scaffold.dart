import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

import '../providers/shell_layout_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: title,
            breadcrumbs: [moduleLabel.replaceAll(' Module', ''), title],
            actions: actions,
          );
    });

    return ColoredBox(
      color: const Color(0xFFF8F9FF),
      child: body,
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
