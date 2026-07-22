import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/purchase_request.dart';
import '../providers/purchase_request_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PurchaseRequestListScreen extends ConsumerStatefulWidget {
  const PurchaseRequestListScreen({super.key});

  @override
  ConsumerState<PurchaseRequestListScreen> createState() =>
      _PurchaseRequestListScreenState();
}

class _PurchaseRequestListScreenState
    extends ConsumerState<PurchaseRequestListScreen> {
  String _selectedStatus = 'ALL';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Purchase Requests',
            actions: [],
            breadcrumbs: ['Inventory', 'Purchase Requests'],
          );
    });
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prAsync = ref.watch(purchaseRequestsProvider);

    final authState = ref.watch(authProvider);
    final currentUserFullName = authState.profile?.fullName ?? 'John Doe';
    final currentUserId = authState.user?.id ?? ApiService.mockUserUuid;

    // Detect draft
    final draftRequest = prAsync.whenData((list) => list
        .where((pr) =>
            pr.status.toUpperCase() == 'DRAFT' &&
            (pr.createdById != null
                ? pr.createdById == currentUserId
                : pr.createdBy.toLowerCase() == currentUserFullName.toLowerCase()))
        .firstOrNull).value;
    final hasDraft = draftRequest != null;
    final draftItemCount = draftRequest?.totalItems ?? 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draft Banner
              if (hasDraft) _buildDraftBanner(theme, draftRequest, draftItemCount),

              // Top Bar: Filter by & Create New Request button
              _buildTopBar(theme, hasDraft, draftItemCount),
              const SizedBox(height: 8),

              // Sub-caption note
              Text(
                '* Purchase requests may contain items from multiple suppliers.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Main Table Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: prAsync.when(
                    data: (requests) {
                      final filteredRequests = requests.where((pr) {
                        if (pr.status.toUpperCase() == 'DRAFT') {
                          final isOwner = pr.createdById != null
                              ? pr.createdById == currentUserId
                              : pr.createdBy.toLowerCase() ==
                                  currentUserFullName.toLowerCase();
                          if (!isOwner) return false;
                        }

                        if (_selectedStatus == 'ALL') return true;
                        return pr.status.toUpperCase() == _selectedStatus.toUpperCase();
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (filteredRequests.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  'No purchase requests found for status "$_selectedStatus".',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  theme.colorScheme.surfaceContainerLow,
                                ),
                                headingRowHeight: 48,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                                horizontalMargin: 16,
                                columnSpacing: 20,
                                headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Request ID')),
                                  DataColumn(label: Text('Request Date')),
                                  DataColumn(label: Text('ESTIMATED TOTAL')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Created By')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: filteredRequests.map((pr) {
                                  final estTotal = pr.totalQuantity * 150000;
                                  final reqIdStr =
                                      '#REQ-2024-${pr.purchaseRequestNumber.toString().padLeft(3, '0')}';
                                  final dateStr = pr.createdDate != null
                                      ? DateFormat('MMM dd, yyyy').format(pr.createdDate!)
                                      : 'Oct 24, 2023';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          reqIdStr,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          dateStr,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatCurrency(estTotal),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _buildStatusBadge(theme, pr.status),
                                      ),
                                      DataCell(
                                        Text(
                                          pr.createdBy,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined),
                                              color: theme.colorScheme.primary,
                                              tooltip: 'View Detail',
                                              onPressed: () => _showRequestDetails(
                                                context,
                                                pr.purchaseRequestNumber,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined),
                                              color: theme.colorScheme.primary,
                                              tooltip: 'Edit',
                                              onPressed: () => context.push('/stock/purchase-requests/create'),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                pr.status.toUpperCase() == 'REJECTED'
                                                    ? Icons.refresh_outlined
                                                    : Icons.cancel_outlined,
                                              ),
                                              color: pr.status.toUpperCase() == 'REJECTED'
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.error,
                                              tooltip: pr.status.toUpperCase() == 'REJECTED'
                                                  ? 'Re-submit'
                                                  : 'Cancel',
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                          const SizedBox(height: 16),
                          Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),

                          // Table Footer Pagination
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing 1 to ${filteredRequests.length} of ${requests.length} entries',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildPageBox('<', isSelected: false, onTap: () {
                                    if (_currentPage > 1) setState(() => _currentPage--);
                                  }),
                                  const SizedBox(width: 4),
                                  _buildPageBox('1', isSelected: _currentPage == 1, onTap: () {
                                    setState(() => _currentPage = 1);
                                  }),
                                  const SizedBox(width: 4),
                                  _buildPageBox('2', isSelected: _currentPage == 2, onTap: () {
                                    setState(() => _currentPage = 2);
                                  }),
                                  const SizedBox(width: 4),
                                  _buildPageBox('3', isSelected: _currentPage == 3, onTap: () {
                                    setState(() => _currentPage = 3);
                                  }),
                                  const SizedBox(width: 4),
                                  _buildPageBox('>', isSelected: false, onTap: () {
                                    setState(() => _currentPage++);
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error loading requests: $err'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Bottom Row (Request Volume Trend & Pending Total)
              prAsync.when(
                data: (requests) {
                  final pendingRequests = requests.where((pr) => pr.status.toUpperCase() == 'PENDING').toList();
                  final pendingVal = pendingRequests.fold<double>(
                    0.0,
                    (sum, pr) => sum + (pr.totalQuantity * 150000),
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 850;

                      Widget trendCard = Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Request Volume Trend',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.colorScheme.outlineVariant),
                                    ),
                                    child: Text(
                                      '[Note: Weekly Velocity]',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildVolumeBarChart(theme),
                            ],
                          ),
                        ),
                      );

                      Widget pendingCard = Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Total',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _formatCurrency(pendingVal > 0 ? pendingVal : 12450000),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Est. value of ${pendingRequests.isNotEmpty ? pendingRequests.length : 14} requests',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Download Report',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: trendCard),
                            const SizedBox(width: 20),
                            Expanded(flex: 1, child: pendingCard),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            trendCard,
                            const SizedBox(height: 20),
                            pendingCard,
                          ],
                        );
                      }
                    },
                  );
                },
                loading: () => const SizedBox(),
                error: (err, stack) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Section 3: Internal Notes Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Internal Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        '[System Alert]: 3 Requests for "Lithium Batteries" are flagged for "Urgent Approval" due to low inventory levels at Warehouse B.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please ensure all supplier certifications are attached before final submission to finance.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool hasDraft, int draftItemCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;

        Widget filterTabs = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );

        Widget createBtn = FilledButton.icon(
          onPressed: () async {
            final result = await context.push('/stock/purchase-requests/create');
            if (result == true && context.mounted) {
              ref.invalidate(purchaseRequestsProvider);
            }
          },
          icon: const Icon(Icons.add, size: 20),
          label: Text(hasDraft ? 'Continue Draft ($draftItemCount)' : 'Create New Request'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              filterTabs,
              createBtn,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterTabs,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: createBtn),
            ],
          );
        }
      },
    );
  }

  Widget _buildDraftBanner(ThemeData theme, PurchaseRequestList draft, int itemCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have an unsubmitted draft',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  itemCount > 0
                      ? '$itemCount item(s) saved — continue editing before submitting'
                      : 'Empty draft — add products then submit for approval',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await context.push('/stock/purchase-requests/create');
              if (result == true && context.mounted) {
                ref.invalidate(purchaseRequestsProvider);
              }
            },
            child: const Text('Continue →'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBox(String text, {required bool isSelected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        color = theme.colorScheme.primary;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'REJECTED':
        color = theme.colorScheme.error;
        break;
      default:
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Text(
      status.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVolumeBarChart(ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final heights = [30.0, 55.0, 40.0, 25.0, 50.0, 20.0, 45.0];

    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: heights[index],
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[index],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _showRequestDetails(BuildContext context, int prNumber) async {
    final theme = Theme.of(context);
    final apiService = ApiService();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<PurchaseRequestDetail>(
              future: apiService.fetchPurchaseRequestDetail(prNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Purchase request details cannot be loaded.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }

                final detail = snapshot.data!;
                final totalPrCost = detail.items.fold<double>(
                  0.0,
                  (sum, item) =>
                      sum + (item.requestedQuantity * item.importPrice),
                );

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Purchase Request #${detail.purchaseRequestNumber}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created by: ${detail.createdBy}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusBadge(theme, detail.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _buildDetailField(
                            'Created Date',
                            detail.createdDate != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(detail.createdDate!)
                                : 'N/A',
                          ),
                          if (detail.approvedBy != null) ...[
                            _buildDetailField(
                              'Approved By',
                              detail.approvedBy!,
                            ),
                            _buildDetailField(
                              'Approved Date',
                              detail.approvedDate != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(detail.approvedDate!)
                                  : 'N/A',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Requested Items',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingTextStyle: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                columns: const [
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('SKU')),
                                  DataColumn(label: Text('Supplier')),
                                  DataColumn(label: Text('Qty')),
                                  DataColumn(label: Text('Import Price')),
                                  DataColumn(label: Text('Total')),
                                ],
                                rows: detail.items.map((item) {
                                  final total =
                                      item.requestedQuantity * item.importPrice;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item.productName)),
                                      DataCell(Text(item.sku)),
                                      DataCell(Text(item.supplierName)),
                                      DataCell(
                                        Text(
                                          '${_formatQuantity(item.requestedQuantity)} ${item.unitName}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(_formatCurrency(item.importPrice)),
                                      ),
                                      DataCell(
                                        Text(_formatCurrency(total)),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'ESTIMATED TOTAL COST: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatCurrency(totalPrCost),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                          if (detail.status.toUpperCase() == 'DRAFT') ...[
                            const SizedBox(width: 8),
                            (() {
                              bool isSubmitting = false;
                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return isSubmitting
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : FilledButton.icon(
                                          onPressed: () async {
                                            setDialogState(() {
                                              isSubmitting = true;
                                            });
                                            try {
                                              final ok = await apiService
                                                  .submitPurchaseRequestForApproval(
                                                    detail.purchaseRequestNumber,
                                                  );
                                              if (!ok) {
                                                throw Exception('Server rejected request.');
                                              }
                                              if (context.mounted) {
                                                Navigator.pop(dialogContext);
                                                ref.invalidate(purchaseRequestsProvider);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Purchase request submitted for approval successfully.',
                                                    ),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setDialogState(() {
                                                isSubmitting = false;
                                              });
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to submit: $e'),
                                                    backgroundColor: theme.colorScheme.error,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.send_outlined),
                                          label: const Text('Submit for Approval'),
                                        );
                                },
                              );
                            })(),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
