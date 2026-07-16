import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/purchase_request.dart';
import '../providers/purchase_request_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../providers/dashboard_provider.dart';

class PurchaseRequestListScreen extends ConsumerStatefulWidget {
  const PurchaseRequestListScreen({super.key});

  @override
  ConsumerState<PurchaseRequestListScreen> createState() =>
      _PurchaseRequestListScreenState();
}

class _InventorySearchController extends TextEditingController {}

class _PurchaseRequestListScreenState
    extends ConsumerState<PurchaseRequestListScreen> {
  final _InventorySearchController _searchController =
      _InventorySearchController();
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: 'Purchase Requests',
            actions: [],
            breadcrumbs: ['Inventory', 'Purchase Requests'],
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prAsync = ref.watch(purchaseRequestsProvider);

    // Detect if there's an existing draft with items
    final draftRequest = prAsync.whenData((list) =>
      list.where((pr) => pr.status.toUpperCase() == 'DRAFT').firstOrNull
    ).value;
    final hasDraft = draftRequest != null;
    final draftItemCount = draftRequest?.totalItems ?? 0;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Draft Banner
            if (hasDraft) _buildDraftBanner(theme, draftRequest, draftItemCount),
            Expanded(
              child: Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filters Header Section
                    _buildFiltersHeader(theme, hasDraft, draftItemCount),
                    const Divider(height: 1),

              // Main List/Table Section
              Expanded(
                child: prAsync.when(
                  data: (requests) {
                    final filteredRequests = requests.where((pr) {
                      final matchesStatus =
                          _selectedStatus == 'ALL' ||
                          pr.status.toUpperCase() ==
                              _selectedStatus.toUpperCase();
                      final matchesSearch =
                          pr.purchaseRequestNumber.toString().contains(
                            _searchQuery,
                          ) ||
                          pr.createdBy.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          pr.supplierName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      return matchesStatus && matchesSearch;
                    }).toList();

                    if (filteredRequests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No purchase requests found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search query or status filter.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(purchaseRequestsProvider);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingTextStyle: theme.textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 56,
                              columns: const [
                                DataColumn(label: Text('PR ID')),
                                DataColumn(label: Text('Created By')),
                                DataColumn(label: Text('Created Date')),
                                DataColumn(label: Text('Supplier')),
                                DataColumn(label: Text('Items Count')),
                                DataColumn(label: Text('Total Qty')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredRequests.map((pr) {
                                return DataRow(
                                  onSelectChanged: (_) => _showRequestDetails(
                                    context,
                                    pr.purchaseRequestNumber,
                                  ),
                                  cells: [
                                    DataCell(
                                      Text('#${pr.purchaseRequestNumber}'),
                                    ),
                                    DataCell(Text(pr.createdBy)),
                                    DataCell(
                                      Text(
                                        pr.createdDate != null
                                            ? DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(pr.createdDate!)
                                            : 'N/A',
                                      ),
                                    ),
                                    DataCell(Text(pr.supplierName)),
                                    DataCell(Text('${pr.totalItems}')),
                                    DataCell(Text('${pr.totalQuantity}')),
                                    DataCell(
                                      _buildStatusBadge(theme, pr.status),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        tooltip: 'View Details',
                                        color: theme.colorScheme.primary,
                                        onPressed: () => _showRequestDetails(
                                          context,
                                          pr.purchaseRequestNumber,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.1,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              'Purchase request data cannot be loaded.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err
                                  .toString()
                                  .replaceAll('Exception:', '')
                                  .trim(),
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  ref.invalidate(purchaseRequestsProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),    // Expanded(child: prAsync.when)
              ),      // Expanded
                  ],  // Card Column children
                ),    // Card Column
              ),      // Card
            ),        // outer Expanded
          ],          // outer Column children
        ),            // outer Column
      ),              // Padding
    );
  }

  Widget _buildDraftBanner(ThemeData theme, PurchaseRequestList draft, int itemCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF40826D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF40826D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF40826D).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF40826D),
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
                    color: const Color(0xFF2F5D50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  itemCount > 0
                      ? '$itemCount item(s) saved — continue editing before submitting'
                      : 'Empty draft — add products then submit for approval',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF40826D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final result = await context.push('/stock/purchase-requests/create');
              if (result == true && context.mounted) {
                ref.invalidate(purchaseRequestsProvider);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF40826D),
            ),
            child: const Text('Continue →'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersHeader(ThemeData theme, bool hasDraft, int draftItemCount) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Box
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ID, creator, supplier...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
            ),
          ),

          // Status Tabs/Filters
          Wrap(
            spacing: 8,
            children:
                [
                  'ALL',
                  'DRAFT',
                  'PENDING',
                  'APPROVED',
                  'REJECTED',
                  'COMPLETED',
                ].map((status) {
                  final isSelected = _selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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

          // Create / Continue Draft Button
          SizedBox(
            height: 48,
            child: hasDraft
                ? FilledButton.icon(
                    onPressed: () async {
                      final result = await context.push('/stock/purchase-requests/create');
                      if (result == true && context.mounted) {
                        ref.invalidate(purchaseRequestsProvider);
                      }
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Continue Draft'),
                        if (draftItemCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$draftItemCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF40826D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () async {
                      final result = await context.push('/stock/purchase-requests/create');
                      if (result == true && context.mounted) {
                        ref.invalidate(purchaseRequestsProvider);
                      }
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create New Request'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color color;
    Color bg;

    switch (status.toUpperCase()) {
      case 'DRAFT':
        color = Colors.blueGrey;
        bg = Colors.blueGrey.withValues(alpha: 0.1);
        break;
      case 'APPROVED':
        color = Colors.green;
        bg = Colors.green.withValues(alpha: 0.1);
        break;
      case 'PENDING':
        color = Colors.orange;
        bg = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'REJECTED':
        color = theme.colorScheme.error;
        bg = theme.colorScheme.error.withValues(alpha: 0.1);
        break;
      case 'COMPLETED':
        color = theme.colorScheme.primary;
        bg = theme.colorScheme.primary.withValues(alpha: 0.1);
        break;
      default:
        color = theme.colorScheme.onSurfaceVariant;
        bg = theme.colorScheme.surfaceContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showRequestDetails(BuildContext context, int prNumber) async {
    final theme = Theme.of(context);
    final apiService = ref.read(apiServiceProvider);

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
                      // Dialog Title / Header
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

                      // Request details grid
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _buildDetailField(
                            'Created Date',
                            detail.createdDate != null
                                ? DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(detail.createdDate!)
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
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(detail.approvedDate!)
                                  : 'N/A',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Items Table
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
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
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
                                          '${item.requestedQuantity} ${item.unitName}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '\$${item.importPrice.toStringAsFixed(2)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text('\$${total.toStringAsFixed(2)}'),
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

                      // Cost summary row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Estimated Total Cost: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${totalPrCost.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Actions Button
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
                                                    detail
                                                        .purchaseRequestNumber,
                                                  );
                                              if (!ok) {
                                                throw Exception(
                                                  'Server rejected request.',
                                                );
                                              }
                                              if (context.mounted) {
                                                Navigator.pop(dialogContext);
                                                ref.invalidate(
                                                  purchaseRequestsProvider,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Purchase request submitted for approval successfully.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setDialogState(() {
                                                isSubmitting = false;
                                              });
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to submit: $e',
                                                    ),
                                                    backgroundColor:
                                                        theme.colorScheme.error,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.send_outlined),
                                          label: const Text(
                                            'Submit for Approval',
                                          ),
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
