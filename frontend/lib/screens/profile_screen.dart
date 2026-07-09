import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_button.dart';
import 'package:frontend/widgets/shared/app_card.dart';
import 'package:frontend/widgets/shared/app_outlined_button.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/shifts_table.dart';
import 'package:frontend/widgets/certifications_list.dart';
import 'package:frontend/widgets/performance_summary.dart';
import 'package:frontend/core/errors/app_error.dart';

class ProfileScreen extends ConsumerWidget {
  final int employeeId;

  const ProfileScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeDetailProvider(employeeId));

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
          'Employee Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          const Padding(
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
        data: (emp) => PageContainer(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(employeeDetailProvider(employeeId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 16),

                // 1. Profile Card
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          UserAvatar(name: emp.name, imageUrl: emp.imageUrl, radius: 48),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emp.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${emp.role.replaceAll('_', ' ')} • ${emp.employeeCode}'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Assign Shift',
                              icon: Icons.calendar_today,
                              onPressed: () => context.push('/schedule/$employeeId'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppOutlinedButton(
                              text: 'Change Role',
                              icon: Icons.badge_outlined,
                              onPressed: () => context.push('/role/$employeeId'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.email_outlined, emp.email),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_outlined, emp.phone),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on_outlined, emp.location),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Joined: ${DateFormat('MMMM d, yyyy').format(emp.joinedDate)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Performance Summary
                Text(
                  'Performance Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                PerformanceSummary(employee: emp),
                const SizedBox(height: 24),

                // 3. Recent Shifts Table
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Shifts',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All History',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ShiftsTable(recentShifts: emp.recentShifts),
                const SizedBox(height: 24),

                // 4. Certifications
                Text(
                  'Certifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                CertificationsList(certifications: emp.certifications),
                const SizedBox(height: 24),

                // 5. Manager's Note
                if (emp.managersNote != null && emp.managersNote!.isNotEmpty) ...[
                  Text(
                    "Manager's Note",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(244, 162, 97, 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color.fromRGBO(244, 162, 97, 0.3), width: 1),
                    ),
                    child: Text(
                      '"${emp.managersNote}"',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: AppTheme.secondaryDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const LoadingView(message: 'Đang tải hồ sơ nhân viên...'),
        error: (err, stack) {
          final message = err is AppError ? err.userMessage : 'Không thể tải chi tiết nhân viên. Vui lòng thử lại.';
          return ErrorView(
            message: message,
            onRetry: () => ref.invalidate(employeeDetailProvider(employeeId)),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
