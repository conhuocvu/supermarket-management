import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/auth_provider.dart';
import '../providers/cashier_provider.dart';
import '../widgets/role_module_scaffold.dart';
import '../widgets/attendance_card.dart';
import '../widgets/bento_card.dart';

class CashierDashboardScreen extends ConsumerStatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  ConsumerState<CashierDashboardScreen> createState() =>
      _CashierDashboardScreenState();
}

class _CashierDashboardScreenState
    extends ConsumerState<CashierDashboardScreen> {
  Future<CashierDashboardData>? _future;
  int? _loadedDataVersion;

  Future<CashierDashboardData> _load() {
    final cashierId = ref.read(authProvider).profile?.userId;
    if (cashierId == null || cashierId.isEmpty) {
      return Future.error('Cashier profile is not available.');
    }
    return ref.read(cashierApiServiceProvider).dashboard(cashierId);
  }

  @override
  Widget build(BuildContext context) {
    final dataVersion = ref.watch(cashierDataVersionProvider);
    if (_future == null || _loadedDataVersion != dataVersion) {
      _loadedDataVersion = dataVersion;
      _future = _load();
    }

    return RoleModuleScaffold(
      moduleLabel: 'Cashier Module',
      title: 'Cashier Dashboard',
      navigationItems: cashierNavigationItems,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => setState(() => _future = _load()),
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
      body: FutureBuilder<CashierDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _error(snapshot.error.toString());
          return _content(snapshot.data!);
        },
      ),
    );
  }

  Widget _content(CashierDashboardData data) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, actionConstraints) {
                  final isWideAction = actionConstraints.maxWidth >= 750;
                  if (isWideAction) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 3,
                          child: AttendanceCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildPersonalActions(context),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        const AttendanceCard(),
                        const SizedBox(height: 16),
                        _buildPersonalActions(context),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(
                      data.currentShift.name.startsWith('No active shift')
                          ? 'No active shift · showing today\'s invoices'
                          : '${data.currentShift.name}: '
                                '${formatTime(data.currentShift.startDateTime)} - '
                                '${formatTime(data.currentShift.endDateTime)}',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.person_outline_rounded, size: 18),
                    label: Text(
                      ref.watch(authProvider).profile?.fullName ?? 'Cashier',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 14) / columns;
                  final cards = [
                    (
                      'Shift Invoices',
                      '${data.invoiceCount}',
                      Icons.receipt_long,
                    ),
                    (
                      'Shift Revenue',
                      formatMoney(data.revenue),
                      Icons.payments_outlined,
                    ),
                    (
                      'Current Shift',
                      data.currentShift.name,
                      Icons.schedule_outlined,
                    ),
                    (
                      'Unpaid Invoices',
                      '${data.unpaidInvoiceCount}',
                      Icons.pending_actions,
                    ),
                  ];
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: cards.map((item) {
                      return SizedBox(
                        width: width,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.$3, color: theme.colorScheme.primary),
                                const SizedBox(height: 18),
                                Text(
                                  item.$2,
                                  style: theme.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/cashier/new-invoice'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Invoice'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(170, 52),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/cashier/invoices'),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View Shift Invoices'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(210, 52),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Recent invoices', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              _recentInvoices(data.recentInvoices),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentInvoices(List<CashierInvoiceSummary> invoices) {
    if (invoices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('No invoices have been created in this shift.'),
          ),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Invoice')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: invoices.map((invoice) {
            return DataRow(
              cells: [
                DataCell(Text('#${invoice.invoiceNumber}')),
                DataCell(Text(formatDateTime(invoice.createdDate))),
                DataCell(Text(invoice.customerName)),
                DataCell(Text(formatMoney(invoice.finalAmount))),
                DataCell(Text(invoice.paymentMethod ?? '—')),
                DataCell(_status(invoice.status)),
                DataCell(
                  IconButton(
                    tooltip: 'View invoice',
                    onPressed: () => context.go(
                      '/cashier/invoices/${invoice.invoiceNumber}',
                    ),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _status(String status) {
    final value = status.toUpperCase();
    final color = switch (value) {
      'PAID' => const Color(0xFF16794A),
      'CANCELLED' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };
    return Chip(
      label: Text(value),
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }

  Widget _error(String raw) {
    final message = raw.replaceFirst('Exception: ', '');
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 52),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => setState(() => _future = _load()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalActions(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Work Schedule',
            route: '/work-schedule',
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            context,
            icon: Icons.time_to_leave_outlined,
            label: 'Request Leave',
            route: '/leave-request',
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            context,
            icon: Icons.published_with_changes_outlined,
            label: 'Shift Change Request',
            route: '/schedule-change',
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            context,
            icon: Icons.rule_folder_outlined,
            label: 'Manage My Requests',
            route: '/manage-requests',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
