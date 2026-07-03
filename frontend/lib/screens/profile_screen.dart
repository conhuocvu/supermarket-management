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
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: UserAvatar(
              name: "David Okafor",
              imageUrl:
                  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          UserAvatar(
                              name: emp.name,
                              imageUrl: emp.imageUrl,
                              radius: 48),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${emp.role} • ${emp.employeeCode}'.toUpperCase(),
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
                              onPressed: () =>
                                  context.push('/schedule/$employeeId'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppOutlinedButton(
                              text: 'Change Role',
                              icon: Icons.badge_outlined,
                              onPressed: () =>
                                  context.push('/role/$employeeId'),
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
                      _buildInfoRow(
                          Icons.location_on_outlined, emp.location),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromRGBO(34, 197, 94, 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.check_circle_outline,
                                  color: AppTheme.success),
                            ),
                            const SizedBox(height: 12),
                            const Text('Attendance Rate',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${emp.attendanceRate.toInt()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.trending_up,
                                        color: AppTheme.success, size: 16),
                                    SizedBox(width: 2),
                                    Text('+2%',
                                        style: TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromRGBO(59, 130, 246, 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.schedule,
                                  color: AppTheme.info),
                            ),
                            const SizedBox(height: 12),
                            const Text('Completed Shifts',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${emp.completedShifts}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Text('Total',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(168, 213, 194, 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star_outline,
                            color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Performance Score',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${emp.performanceScore} / 5.0',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PEAK PERFORMANCE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Recent Shifts Table
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Shifts',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All History',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildShiftsTable(emp.recentShifts, context),
                const SizedBox(height: 24),

                // 4. Certifications
                Text(
                  'Certifications',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildCertifications(emp.certifications),
                const SizedBox(height: 24),

                // 5. Manager's Note
                if (emp.managersNote != null &&
                    emp.managersNote!.isNotEmpty) ...[
                  Text(
                    "Manager's Note",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(244, 162, 97, 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color.fromRGBO(244, 162, 97, 0.3),
                          width: 1),
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
        loading: () =>
            const LoadingView(message: 'Đang tải hồ sơ nhân viên...'),
        error: (err, stack) => ErrorView(
          message: 'Không thể tải chi tiết nhân viên. Vui lòng thử lại.',
          onRetry: () => ref.invalidate(employeeDetailProvider(employeeId)),
        ),
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

  Widget _buildShiftsTable(List recentShifts, BuildContext context) {
    if (recentShifts.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa có ca làm việc nào gần đây.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                    child: Text('DATE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary))),
                Expanded(
                    child: Text('DURATION',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary))),
                Expanded(
                    child: Text('REGISTER',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary))),
              ],
            ),
          ),
          for (final shift in recentShifts.take(3))
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: AppTheme.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, yyyy').format(shift.date),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${shift.startTime} - ${shift.endTime}',
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      shift.register ?? 'Floor / Stock',
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCertifications(List certifications) {
    if (certifications.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa đạt chứng chỉ nào.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final cert in certifications)
            ListTile(
              leading: Icon(
                cert.expiryDate != null &&
                        cert.expiryDate!.isBefore(DateTime.now())
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                color: cert.expiryDate != null &&
                        cert.expiryDate!.isBefore(DateTime.now())
                    ? AppTheme.error
                    : AppTheme.primary,
              ),
              title: Text(cert.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              subtitle: Text(
                cert.expiryDate != null
                    ? 'Expires: ${DateFormat('MMM yyyy').format(cert.expiryDate!)}'
                    : 'Obtained: ${DateFormat('MMM yyyy').format(cert.obtainedDate)}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
