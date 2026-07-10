import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/promotion.dart';
import 'package:frontend/providers/promotion_provider.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_search_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/empty_view.dart';
import 'package:frontend/widgets/shared/smart_image.dart';

class PromotionListScreen extends ConsumerStatefulWidget {
  const PromotionListScreen({super.key});

  @override
  ConsumerState<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends ConsumerState<PromotionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentUserRoleProvider);
    final promotionsAsync = ref.watch(promotionsProvider);

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
          'Promotion Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              currentRole,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            ref.invalidate(promotionsProvider);
          },
          child: promotionsAsync.when(
            loading: () => const LoadingView(),
            error: (err, stack) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(promotionsProvider),
            ),
            data: (promotions) {
              // Separate active/pending (near term) from upcoming campaigns (starts in > 10 days)
              final now = DateTime.now();
              final upcomingThreshold = now.add(const Duration(days: 10));

              final currentPromoList = promotions.where((p) {
                return p.startDate.isBefore(upcomingThreshold);
              }).toList();

              final upcomingPromoList = promotions.where((p) {
                return p.startDate.isAfter(upcomingThreshold);
              }).toList();

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create and manage seasonal offers and store-wide discounts',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  AppSearchField(
                    hint: 'Search promotions...',
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(promotionSearchQueryProvider.notifier).state = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFilterChips(context),
                  const SizedBox(height: 24),
                  
                  if (currentPromoList.isEmpty && upcomingPromoList.isEmpty)
                    const EmptyView(
                      title: 'No promotions found',
                      description: 'There are currently no promotions matching your criteria.',
                    )
                  else ...[
                    // Main current cards
                    ...currentPromoList.map((p) => _buildPromotionCard(context, p)),
                    
                    // Upcoming section
                    if (upcomingPromoList.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Upcoming Campaigns',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...upcomingPromoList.map((p) => _buildUpcomingCard(context, p)),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: (currentRole == 'ADMIN' || currentRole == 'MANAGER')
          ? FloatingActionButton(
              onPressed: () => context.push('/promotions/new'),
              backgroundColor: AppTheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Promotion'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Supplier'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_outlined), label: 'Reports'),
        ],
        onTap: (index) {
          if (index == 1) {
            context.go('/');
          } else if (index == 2) {
            // Already here
          } else if (index == 3) {
            context.go('/suppliers');
          }
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final activeFilter = ref.watch(promotionCategoryFilterProvider);
    final filters = [
      {'label': 'All', 'value': 'ALL'},
      {'label': 'Seasonal', 'value': 'Seasonal'},
      {'label': 'BOGO', 'value': 'BOGO'},
      {'label': 'Flash Sale', 'value': 'Flash Sale'},
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
                  ref.read(promotionCategoryFilterProvider.notifier).state = f['value']!;
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

  Widget _buildPromotionCard(BuildContext context, Promotion promotion) {
    final hasImage = promotion.imageUrl.isNotEmpty;
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final isExpired = promotion.status == 'EXPIRED';
    final isPending = promotion.status == 'PENDING';
    final isWriteAllowed = ref.read(currentUserRoleProvider) == 'ADMIN' || ref.read(currentUserRoleProvider) == 'MANAGER';

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isExpired) {
      badgeBg = AppTheme.error.withOpacity(0.1);
      badgeText = AppTheme.error;
      badgeLabel = 'Expired';
    } else if (isPending) {
      badgeBg = AppTheme.warning.withOpacity(0.1);
      badgeText = AppTheme.secondaryDark;
      badgeLabel = 'Pending';
    } else {
      badgeBg = AppTheme.primary.withOpacity(0.1);
      badgeText = AppTheme.primary;
      badgeLabel = 'Active';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SmartImage(
                imageUrl: promotion.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        promotion.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  promotion.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isPending ? Icons.access_time : Icons.calendar_today_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPending
                          ? 'Starts ${formatter.format(promotion.startDate)}'
                          : 'Ends ${formatter.format(promotion.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isWriteAllowed) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/promotions/edit/${promotion.id}'),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/promotions/${promotion.id}'),
                        child: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, Promotion promotion) {
    final DateFormat formatter = DateFormat('MMM dd');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.campaign_outlined, color: AppTheme.primary),
          ),
        ),
        title: Text(
          promotion.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Scheduled for ${formatter.format(promotion.startDate)} - ${formatter.format(promotion.endDate)}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: () => context.push('/promotions/${promotion.id}'),
      ),
    );
  }
}
