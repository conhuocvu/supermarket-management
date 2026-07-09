import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/promotion.dart';
import 'package:frontend/providers/promotion_provider.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/smart_image.dart';

class PromotionDetailScreen extends ConsumerWidget {
  final int promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionAsync = ref.watch(promotionDetailProvider(promotionId));
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
          'Promotion Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.textPrimary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: promotionAsync.when(
        loading: () => const LoadingView(),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(promotionDetailProvider(promotionId)),
        ),
        data: (promotion) {
          return PageContainer(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderBanner(context, promotion),
                  const SizedBox(height: 20),
                  Text(
                    promotion.description.isNotEmpty
                        ? promotion.description
                        : 'No description provided.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildCodeCard(context, promotion),
                  const SizedBox(height: 24),
                  _buildConfigurationSection(context, promotion),
                  const SizedBox(height: 24),
                  if (isWriteAllowed) ...[
                    _buildActionButtons(context, ref, promotion),
                    const SizedBox(height: 24),
                  ],
                  _buildPerformanceSection(context, promotion),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, Promotion promotion) {
    final isExpired = promotion.status == 'EXPIRED';
    final isPending = promotion.status == 'PENDING';

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isExpired) {
      badgeBg = AppTheme.error;
      badgeText = Colors.white;
      badgeLabel = 'Expired';
    } else if (isPending) {
      badgeBg = AppTheme.warning;
      badgeText = Colors.white;
      badgeLabel = 'Pending';
    } else {
      badgeBg = AppTheme.primaryLight;
      badgeText = AppTheme.primaryDark;
      badgeLabel = 'Active';
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        children: [
          if (promotion.imageUrl.isNotEmpty)
            SmartImage(
              imageUrl: promotion.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(16),
            ),
          // Dark overlay to read text
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  promotion.name,
                  style: const TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, Promotion promotion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text(
            'Promotion Code',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            promotion.code,
            style: const TextStyle(
              fontFamily: 'Bricolage Grotesque',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: promotion.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied promotion code to clipboard!'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection(BuildContext context, Promotion promotion) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final discountStr = promotion.discountType == 'PERCENTAGE'
        ? '${promotion.discountValue.toStringAsFixed(0)}%'
        : '\$${promotion.discountValue.toStringAsFixed(2)}';
    
    final discountTypeStr = promotion.discountType == 'PERCENTAGE'
        ? 'Percentage'
        : 'Fixed Amount';

    final targetProductsStr = promotion.targetProducts.isEmpty
        ? 'None'
        : promotion.targetProducts.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Configuration Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildConfigItem('DISCOUNT', discountStr),
        _buildConfigItem('TYPE', discountTypeStr),
        _buildConfigItem('PRODUCTS', targetProductsStr),
        _buildConfigItem('START DATE', formatter.format(promotion.startDate)),
        _buildConfigItem('END DATE', formatter.format(promotion.endDate)),
        _buildConfigItem('VISIBILITY', promotion.visibility),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Divider(height: 12, color: AppTheme.border),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Promotion promotion) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/promotions/edit/${promotion.id}'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Promotion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DeletePromotionDialog(promotion: promotion),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
            label: const Text('Delete Promotion', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context, Promotion promotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Text('Details', style: TextStyle(color: AppTheme.primary)),
              label: const Icon(Icons.open_in_new, size: 14, color: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(context, Icons.inventory_2_outlined, 'Products Included', '${promotion.productsCount}'),
        const SizedBox(height: 10),
        _buildStatCard(context, Icons.trending_up, 'Est. Revenue Increase', '${promotion.estRevenueIncrease} Target Hit'),
        const SizedBox(height: 10),
        _buildStatCard(context, Icons.shopping_cart_outlined, 'Products Sold', NumberFormat('#,###').format(promotion.productsSold)),
        const SizedBox(height: 10),
        _buildUsageCard(context, promotion.usageRate),
        const SizedBox(height: 16),
        DailyEngagementChart(data: promotion.dailyEngagement),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.textSecondary),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context, int usageRate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_offer_outlined, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Promotion Usage',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Text(
                  '$usageRate%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usageRate / 100.0,
                minHeight: 8,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyEngagementChart extends StatelessWidget {
  final List<int> data;

  const DailyEngagementChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxVal = data.reduce((a, b) => a > b ? a : b);

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
          const Text(
            'Daily Engagement Trend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((val) {
                final double percent = maxVal > 0 ? val / maxVal : 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: percent * 80 + 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 8, color: AppTheme.border),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OCT 12',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
              Text(
                'OCT 19',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeletePromotionDialog extends ConsumerWidget {
  final Promotion promotion;

  const DeletePromotionDialog({super.key, required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.delete_outline, color: AppTheme.error, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Promotion?',
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "${promotion.name}"? This action will immediately end the promotion for all ${promotion.productsCount} applicable products and cannot be undone.',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROMOTION CODE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promotion.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                    child: VerticalDivider(color: AppTheme.border, width: 2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRODUCTS AFFECTED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${promotion.productsCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Close dialog
                      Navigator.of(context).pop();
                      
                      // Trigger delete
                      final notifier = ref.read(promotionsProvider.notifier);
                      final result = await notifier.deletePromotion(promotion.id);
                      
                      if (context.mounted) {
                        if (result.isSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Promotion deleted successfully.'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                          // Go back to list
                          context.go('/promotions');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.error?.userMessage ?? 'Failed to delete promotion.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
