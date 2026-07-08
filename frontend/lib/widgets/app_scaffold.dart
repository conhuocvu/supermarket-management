import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/shell_layout_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final shellState = ref.watch(shellLayoutProvider);
    final displayTitle = title ?? shellState.title;
    final displayActions = actions ?? shellState.actions;

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'active': displayTitle == 'Inventory Dashboard'},
      {'title': 'Products', 'icon': Icons.inventory_2_outlined, 'active': displayTitle == 'Product Management'},
      {'title': 'Categories', 'icon': Icons.category_outlined, 'active': false},
      {'title': 'Transactions', 'icon': Icons.swap_horiz_outlined, 'active': false},
      {'title': 'Low Stock', 'icon': Icons.priority_high_outlined, 'active': false},
      {'title': 'Purchase Requests', 'icon': Icons.shopping_cart_outlined, 'active': false},
      {'title': 'Expiring Products', 'icon': Icons.event_busy_outlined, 'active': false},
      {'title': 'Product Reports', 'icon': Icons.assessment_outlined, 'active': false},
    ];

    Widget buildSidebarContent() {
      return Container(
        color: const Color(0xFFEFF3FF), // surface-container-low
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Staff',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Warehouse v1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF3F4945).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
                        if (item['title'] == 'Dashboard') {
                          context.go('/');
                        } else if (item['title'] == 'Products') {
                          context.go('/products');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['title'] as String,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  // Logout behavior can be wired here
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 256,
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
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFBFC9C3), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
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
          title: Text(displayTitle, style: theme.textTheme.titleLarge),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          actions: displayActions,
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
        ),
        drawer: Drawer(
          child: buildSidebarContent(),
        ),
        body: Material(
          color: const Color(0xFFF8F9FF),
          child: body,
        ),
      );
    }
  }
}
