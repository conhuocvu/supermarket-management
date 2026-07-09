import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_button.dart';
import 'package:frontend/widgets/shared/app_card.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/role_options_list.dart';
import 'package:frontend/widgets/role_permissions_card.dart';
import 'package:frontend/core/errors/app_error.dart';

class ManageRoleScreen extends ConsumerStatefulWidget {
  final int employeeId;

  const ManageRoleScreen({super.key, required this.employeeId});

  @override
  ConsumerState<ManageRoleScreen> createState() => _ManageRoleScreenState();
}

class _ManageRoleScreenState extends ConsumerState<ManageRoleScreen> {
  String? _selectedRole;
  bool _updating = false;
  bool _initialized = false;

  final Map<String, List<String>> _rolePermissions = {
    'MANAGER': [
      'Full System Administration',
      'Employee Management & Scheduling',
      'Financial Auditing & Reporting',
      'High-Value Transaction Approval',
    ],
    'CASHIER': [
      'Point of Sale (POS) Operations',
      'Cash Drawer Management',
      'Returns & Exchanges Processing',
      'Customer Checkout Support',
    ],
    'INVENTORY_STAFF': [
      'Stock Reception & Audit',
      'Warehouse Logistics & Shelving',
      'Low Stock Warnings Configuration',
      'Vendor Delivery Coordination',
    ],
    'SALES_ASSOCIATE': [
      'Customer Service & Sales Support',
      'Floor Merchandising',
      'Price Labeling & Floor Restocking',
      'Basic Inventory Inquiry',
    ],
  };

  final List<Map<String, dynamic>> _roleOptions = [
    {
      'role': 'MANAGER',
      'title': 'Manager',
      'description': 'Full administrative access',
      'icon': Icons.stars_outlined,
      'color': const Color(0xFFA8D5C2),
    },
    {
      'role': 'CASHIER',
      'title': 'Cashier',
      'description': 'POS & Transaction handling',
      'icon': Icons.point_of_sale_outlined,
      'color': const Color(0xFFFDE3CF),
    },
    {
      'role': 'INVENTORY_STAFF',
      'title': 'Inventory Staff',
      'description': 'Stock management & Logistics',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFFC7F3D6),
    },
    {
      'role': 'SALES_ASSOCIATE',
      'title': 'Sales Associate',
      'description': 'Customer service & Sales',
      'icon': Icons.sell_outlined,
      'color': const Color(0xFFE5E7EB),
    },
  ];

  Future<void> _updateRole() async {
    if (_selectedRole == null) return;
    setState(() => _updating = true);

    final result = await ref.read(employeesProvider.notifier).updateRole(widget.employeeId, _selectedRole!);

    setState(() => _updating = false);

    if (!mounted) return;

    if (result.isSuccess) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Employee role updated successfully!'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error?.userMessage ?? 'Failed to update employee role.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeDetailProvider(widget.employeeId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Manage Role',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: UserAvatar(
              name: "David Okafor",
              imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
              radius: 18,
            ),
          ),
        ],
      ),
      body: employeeAsync.when(
        data: (emp) {
          if (!_initialized) {
            _selectedRole = emp.role.toUpperCase();
            _initialized = true;
          }

          return PageContainer(
            child: ListView(
              children: [
                const SizedBox(height: 16),

                // Employee card header
                AppCard(
                  child: Row(
                    children: [
                      UserAvatar(name: emp.name, imageUrl: emp.imageUrl, radius: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  'Current Role: ${emp.role.replaceAll('_', ' ')}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select New Role',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_roleOptions.length} Roles Available',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Role Radio Selection List
                RoleOptionsList(
                  roleOptions: _roleOptions,
                  selectedRole: _selectedRole,
                  onRoleSelected: (role) => setState(() => _selectedRole = role),
                ),

                // Role Permissions card
                RolePermissionsCard(
                  selectedRole: _selectedRole,
                  rolePermissions: _rolePermissions,
                ),

                const SizedBox(height: 32),
                AppButton(
                  text: 'Update Role',
                  icon: Icons.save,
                  isLoading: _updating,
                  onPressed: _updateRole,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const LoadingView(message: 'Đang tải thông tin nhân viên...'),
        error: (err, stack) {
          final message = err is AppError ? err.userMessage : 'Không thể tải chi tiết nhân viên. Vui lòng thử lại.';
          return ErrorView(
            message: message,
            onRetry: () => ref.invalidate(employeeDetailProvider(widget.employeeId)),
          );
        },
      ),
    );
  }
}
