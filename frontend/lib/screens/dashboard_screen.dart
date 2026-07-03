import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_button.dart';
import 'package:frontend/widgets/shared/app_card.dart';
import 'package:frontend/widgets/shared/app_search_field.dart';
import 'package:frontend/widgets/shared/app_text_field.dart';
import 'package:frontend/widgets/shared/empty_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/status_chip.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';

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
    final employeesAsync = ref.watch(employeesProvider);
    final statsAsync = ref.watch(employeeStatsProvider);
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
            imageUrl:
                "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
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
                      child: Text(e,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                ref.read(currentUserRoleProvider.notifier).state = val;
                ref.read(apiServiceProvider).currentUserRole = val;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Simulated user role changed to: $val'),
                  backgroundColor: AppTheme.primary,
                ));
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.textPrimary),
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

              // 1. KPI Stats Cards
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Staff',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${stats['totalStaffCount'] ?? 0}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        168, 213, 194, 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stats['staffCountGrowth'] ?? '+0',
                                    style: const TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'On Shift',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${stats['onShiftCount'] ?? 0}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Live',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Row(
                  children: [
                    Expanded(
                        child: AppCard(
                            child: SizedBox(
                                height: 80,
                                child: Center(
                                    child: CircularProgressIndicator())))),
                    SizedBox(width: 16),
                    Expanded(
                        child: AppCard(
                            child: SizedBox(
                                height: 80,
                                child: Center(
                                    child: CircularProgressIndicator())))),
                  ],
                ),
                error: (err, stack) => AppCard(
                  child: Center(
                      child: Text('Lỗi tải dữ liệu: ${err.toString()}')),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Search Field
              AppSearchField(
                hint: 'Search employee...',
                controller: _searchController,
                onChanged: (value) {
                  ref.read(employeeSearchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              // 3. Status Filters
              _buildFilterChips(context),
              const SizedBox(height: 24),

              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // 4. Employees List
              employeesAsync.when(
                data: (employees) {
                  if (employees.isEmpty) {
                    return const EmptyView(
                      title: 'Không tìm thấy nhân viên',
                      description:
                          'Hãy thử tìm kiếm với tên khác hoặc thay đổi bộ lọc trạng thái.',
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: employees.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = employees[index];
                      String shiftText = '';
                      if (emp.status == 'ON_LEAVE' &&
                          emp.returnsDate != null) {
                        final formatted =
                            '${emp.returnsDate!.day}/${emp.returnsDate!.month}';
                        shiftText = 'RETURNS: $formatted';
                      } else if (emp.recentShifts.isNotEmpty) {
                        final latest = emp.recentShifts.first;
                        final prefix =
                            latest.completed ? 'SHIFT' : 'NEXT SHIFT';
                        shiftText =
                            '$prefix: ${latest.startTime} - ${latest.endTime}';
                      } else {
                        shiftText = 'NO SHIFTS SCHEDULED';
                      }

                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        onTap: () => context.push('/profile/${emp.id}'),
                        child: Row(
                          children: [
                            UserAvatar(
                              name: emp.name,
                              imageUrl: emp.imageUrl,
                              radius: 28,
                              status: emp.status,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        emp.role,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.fiber_manual_record,
                                          size: 6, color: AppTheme.divider),
                                      const SizedBox(width: 6),
                                      StatusChip(status: emp.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    shiftText.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.textSecondary),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingView(
                    isFullScreen: false,
                    message: 'Đang tải danh sách nhân viên...'),
                error: (err, stack) => ErrorView(
                  message:
                      'Không thể tải danh sách nhân viên. Vui lòng kết nối backend.',
                  onRetry: () {
                    ref.invalidate(employeesProvider);
                    ref.invalidate(employeeStatsProvider);
                  },
                ),
              ),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined), label: 'Promotion'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined), label: 'Supplier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined_outlined),
              label: 'Reports'),
        ],
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
                  ref.read(employeeStatusFilterProvider.notifier).state =
                      f['value']!;
                }
              },
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceVariant,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.border),
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

// ---------------------------------------------------------------------------
// Hire Employee Dialog
// ---------------------------------------------------------------------------
class HireEmployeeDialog extends ConsumerStatefulWidget {
  const HireEmployeeDialog({super.key});

  @override
  ConsumerState<HireEmployeeDialog> createState() => _HireEmployeeDialogState();
}

class _HireEmployeeDialogState extends ConsumerState<HireEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedRole = 'CASHIER';
  bool _submitting = false;
  Map<String, String>? _validationErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _validationErrors = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final api = ref.read(apiServiceProvider);
    final result = await api.hireEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result.isSuccess) {
      ref.invalidate(employeesProvider);
      ref.invalidate(employeeStatsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hired new employee successfully!'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      final err = result.error;
      if (err != null && err.code == 'VALIDATION' && err.fieldErrors != null) {
        setState(() => _validationErrors = err.fieldErrors);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err?.userMessage ?? 'Failed to hire employee.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hire New Employee',
          style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                controller: _nameController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nhập họ tên' : null,
              ),
              if (_validationErrors?.containsKey('name') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['name']!,
                    style:
                        const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'a@supermarket.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nhập email' : null,
              ),
              if (_validationErrors?.containsKey('email') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['email']!,
                    style:
                        const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Số điện thoại',
                hint: '0987654321',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.trim().isEmpty
                        ? 'Nhập số điện thoại'
                        : null,
              ),
              if (_validationErrors?.containsKey('phone') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['phone']!,
                    style:
                        const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Chi nhánh / Khu vực làm việc',
                hint: 'Downtown Branch - Zone A',
                controller: _locationController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nhập vị trí' : null,
              ),
              if (_validationErrors?.containsKey('location') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['location']!,
                    style:
                        const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Chức vụ ban đầu',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'MANAGER', child: Text('Manager')),
                  DropdownMenuItem(
                      value: 'CASHIER', child: Text('Cashier')),
                  DropdownMenuItem(
                      value: 'INVENTORY_STAFF',
                      child: Text('Inventory Staff')),
                  DropdownMenuItem(
                      value: 'SALES_ASSOCIATE',
                      child: Text('Sales Associate')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              if (_validationErrors?.containsKey('role') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['role']!,
                    style:
                        const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        AppButton(
          text: 'Hire',
          isLoading: _submitting,
          onPressed: _submit,
          width: 100,
        ),
      ],
    );
  }
}
