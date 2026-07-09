import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_search_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/kpi_stats_cards.dart';
import 'package:frontend/widgets/employee_list_view.dart';
import 'package:frontend/widgets/hire_employee_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: UserAvatar(
            name: "David Okafor",
            imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
            radius: 20,
          ),
        ),
        title: Text(
          'Staff Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          DropdownButton<String>(
            value: currentRole,
            underline: const SizedBox(),
            items: ['ADMIN', 'MANAGER', 'CASHIER']
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                ref.read(currentUserRoleProvider.notifier).state = val;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Simulated user role changed to: $val'),
                  backgroundColor: AppTheme.primary,
                ));
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: PageContainer(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(employeesProvider);
            ref.invalidate(employeeStatsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 16),
              const KpiStatsCards(),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Search employee...',
                controller: _searchController,
                onChanged: (value) {
                  ref.read(employeeSearchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),
              _buildFilterChips(context),
              const SizedBox(height: 24),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const EmployeeListView(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHireEmployeeDialog(context),
        backgroundColor: AppTheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), label: 'Promotion'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Supplier'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_outlined), label: 'Reports'),
        ],
        onTap: (index) {
          if (index == 1) {
            context.go('/');
          } else if (index == 2) {
            context.go('/promotions');
          } else if (index == 3) {
            context.go('/suppliers');
          }
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final activeFilter = ref.watch(employeeStatusFilterProvider);
    final filters = [
      {'label': 'All Staff', 'value': 'ALL'},
      {'label': 'On Duty', 'value': 'ON_DUTY'},
      {'label': 'Off Duty', 'value': 'OFF_DUTY'},
      {'label': 'On Leave', 'value': 'ON_LEAVE'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(employeeStatusFilterProvider.notifier).state = f['value']!;
                }
              },
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceVariant,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showHireEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HireEmployeeDialog(),
    );
  }
}
