import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/supplier.dart';
import 'package:frontend/models/supplier_product.dart';
import 'package:frontend/providers/supplier_provider.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/smart_image.dart';

class SupplierDetailScreen extends ConsumerWidget {
  final int supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierDetailProvider(supplierId));
    final productsAsync = ref.watch(supplierProductsProvider(supplierId));
    final currentRole = ref.watch(currentUserRoleProvider);
    final isWriteAllowed = currentRole == 'ADMIN' || currentRole == 'MANAGER';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Supplier Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                'SM',
                style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: PageContainer(
        child: supplierAsync.when(
          loading: () => const LoadingView(),
          error: (err, stack) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(supplierDetailProvider(supplierId)),
          ),
          data: (supplier) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supplierDetailProvider(supplierId));
                ref.invalidate(supplierProductsProvider(supplierId));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderCard(context, supplier, ref, isWriteAllowed),
                  const SizedBox(height: 24),
                  _buildStatsGrid(context, supplier),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Products',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (isWriteAllowed)
                        TextButton.icon(
                          onPressed: () => context.push('/suppliers/$supplierId/assign'),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Assign Products'),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProductsList(context, productsAsync),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Supplier supplier, WidgetRef ref, bool isWriteAllowed) {
    final isDeactivated = supplier.status == 'Deactivated';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.local_shipping, color: AppTheme.primary, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            supplier.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDeactivated ? Colors.grey[200] : AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isDeactivated ? 'Deactivated' : 'Preferred',
                            style: TextStyle(
                              color: isDeactivated ? Colors.grey[700] : AppTheme.primaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${supplier.code} • ${supplier.notes.isNotEmpty ? supplier.notes : 'Agricultural Logistics Partner'}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isWriteAllowed) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toggleSupplierStatus(context, ref, supplier),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: Text(
                      isDeactivated ? 'Activate' : 'Deactivate',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/suppliers/edit/$supplierId'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Supplier supplier) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          context,
          'ON-TIME DELIVERY',
          '${supplier.onTimeDeliveryRate.toStringAsFixed(0)}%',
          subtitle: '+2.4%',
          subtitleColor: AppTheme.success,
        ),
        _buildStatCard(
          context,
          'PRODUCTS',
          '${supplier.activeSkus}',
          subtitle: 'Active SKUs',
          subtitleColor: AppTheme.textSecondary,
        ),
        _buildStatCard(
          context,
          'AVG. RATING',
          '${supplier.averageRating}/5',
          subtitle: '★ rating',
          subtitleColor: const Color(0xFFC27D38),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value, {
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: subtitleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, AsyncValue<List<SupplierProduct>> productsAsync) {
    return productsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
      error: (err, stack) => Center(child: Text('Failed to load products: $err')),
      data: (list) {
        final assigned = list.where((p) => p.assigned).toList();

        if (assigned.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 12),
                Text(
                  'No products assigned',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Click Assign Products above to add items to this supplier.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assigned.length,
          itemBuilder: (context, index) {
            final sp = assigned[index];
            final savings = sp.basePrice - sp.importPrice;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SmartImage(
                    imageUrl: sp.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  sp.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${sp.sku}',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    if (savings > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Saved \$${savings.toStringAsFixed(2)} / ${sp.unit}',
                        style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${sp.importPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    Text(
                      'per ${sp.unit}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleSupplierStatus(BuildContext context, WidgetRef ref, Supplier supplier) {
    final newStatus = supplier.status == 'Deactivated' ? 'Reliable' : 'Deactivated';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${supplier.status == 'Deactivated' ? 'Activate' : 'Deactivate'} Supplier?'),
        content: Text('Are you sure you want to change the status of ${supplier.name} to $newStatus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final result = await ref.read(suppliersProvider.notifier).updateSupplierStatus(supplier.id, newStatus);
              if (result.isSuccess) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Supplier status updated to $newStatus'),
                  backgroundColor: AppTheme.primary,
                ));
              } else {
                messenger.showSnackBar(SnackBar(
                  content: Text(result.error?.userMessage ?? 'Failed to update status'),
                  backgroundColor: AppTheme.error,
                ));
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
