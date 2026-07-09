import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/supplier.dart';
import 'package:frontend/providers/supplier_provider.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_search_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/empty_view.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentUserRoleProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final isWriteAllowed = currentRole == 'ADMIN' || currentRole == 'MANAGER';

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
          'Supplier Directory',
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
                ref.invalidate(suppliersProvider);
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
            ref.invalidate(suppliersProvider);
          },
          child: suppliersAsync.when(
            loading: () => const LoadingView(),
            error: (err, stack) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(suppliersProvider),
            ),
            data: (suppliers) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Manage wholesale partners, import prices, and delivery schedules across all retail departments.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AppSearchField(
                    hint: 'Search suppliers by name or ID...',
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(supplierSearchQueryProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFilterChips(context),
                  const SizedBox(height: 24),
                  
                  if (suppliers.isEmpty)
                    const EmptyView(
                      title: 'No suppliers found',
                      description: 'There are currently no wholesale suppliers matching your criteria.',
                    )
                  else ...[
                    // Insert the review banner at index 2 if there are multiple items
                    for (int i = 0; i < suppliers.length; i++) ...[
                      _buildSupplierCard(context, suppliers[i]),
                      if (i == 1) _buildQuarterlyReviewBanner(context),
                    ],
                    if (suppliers.length < 2) _buildQuarterlyReviewBanner(context),
                  ],
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: isWriteAllowed
          ? FloatingActionButton(
              onPressed: () => context.push('/suppliers/new'),
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), label: 'Promotion'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Supplier'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_outlined), label: 'Reports'),
        ],
        onTap: (index) {
          if (index == 1) {
            context.go('/');
          } else if (index == 2) {
            context.go('/promotions');
          } else if (index == 3) {
            // Already here
          }
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final activeFilter = ref.watch(supplierCategoryFilterProvider);
    final filters = [
      {'label': 'All Suppliers', 'value': 'ALL'},
      {'label': 'Produce', 'value': 'FRESH PRODUCE'},
      {'label': 'Dairy', 'value': 'DAIRY & COLD'},
      {'label': 'Dry Goods', 'value': 'DRY GOODS'},
      {'label': 'Organic', 'value': 'ORGANIC'},
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
                  ref.read(supplierCategoryFilterProvider.notifier).state = f['value']!;
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

  Widget _buildSupplierCard(BuildContext context, Supplier supplier) {
    final isDeactivated = supplier.status == 'Deactivated';
    final isWarning = supplier.status == 'Warning';

    Color badgeBg;
    Color badgeText;
    if (isDeactivated) {
      badgeBg = Colors.grey.withValues(alpha: 0.15);
      badgeText = Colors.grey;
    } else if (isWarning) {
      badgeBg = AppTheme.warning.withValues(alpha: 0.15);
      badgeText = AppTheme.secondaryDark;
    } else {
      badgeBg = AppTheme.primary.withValues(alpha: 0.15);
      badgeText = AppTheme.primary;
    }

    // Determine custom details depending on category/status
    Widget detailRow;
    if (supplier.certification.isNotEmpty) {
      detailRow = _buildDetailItem(Icons.verified_outlined, 'Certification: ${supplier.certification}');
    } else if (isWarning) {
      detailRow = _buildDetailItem(Icons.history, 'Last Late Delivery: 2 days ago', color: AppTheme.error);
    } else if (supplier.category == 'DRY GOODS') {
      detailRow = _buildDetailItem(Icons.trending_down, 'Price Variance: -4% (Improved)', color: AppTheme.success);
    } else {
      detailRow = _buildDetailItem(Icons.inventory_2_outlined, 'Active SKUs: ${supplier.activeSkus} Items');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  supplier.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC27D38),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    supplier.status,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              supplier.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDeactivated ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              Icons.local_shipping_outlined,
              isDeactivated ? 'Delivery: Deactivated' : 'Next Delivery: ${supplier.nextDelivery}',
            ),
            const SizedBox(height: 8),
            detailRow,
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/suppliers/${supplier.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _handleContact(context, supplier),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: Icon(
                    supplier.contactType == 'phone' ? Icons.phone : Icons.mail_outline,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterlyReviewBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quarterly Supplier Review',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggregate performance data for all active suppliers is now available for the Q3 audit period.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Downloading PDF report...'),
                backgroundColor: AppTheme.primaryDark,
              ));
            },
            icon: const Icon(Icons.download, size: 18, color: AppTheme.primary),
            label: const Text(
              'Download PDF Report',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContact(BuildContext context, Supplier supplier) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${supplier.contactType == 'phone' ? 'Calling' : 'Emailing'} ${supplier.name} at ${supplier.contactValue}'),
      backgroundColor: AppTheme.primary,
    ));
  }
}
