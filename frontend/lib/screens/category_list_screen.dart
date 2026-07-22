import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/category_item.dart';
import '../providers/category_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() =>
      _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: 'Category Management',
            actions: [],
            breadcrumbs: ['Inventory', 'Categories'],
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
    final state = ref.watch(categoryListProvider);

    ref.listen<CategoryListState>(categoryListProvider, (previous, next) {
      if (next.pageError != null && next.pageError != previous?.pageError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.pageError!.replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterHeader(context, theme, state),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildBody(context, theme, state),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterHeader(
    BuildContext context,
    ThemeData theme,
    CategoryListState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        Widget overviewTitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Overview of all active storage categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.normal,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );

        Widget addBtn = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () async {
              final result = await context.push('/stock/categories/add');
              if (result == true && context.mounted) {
                ref
                    .read(categoryListProvider.notifier)
                    .loadCategories(isRefresh: true);
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              overviewTitle,
              addBtn,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              overviewTitle,
              const SizedBox(height: 16),
              addBtn,
            ],
          );
        }
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    CategoryListState state,
  ) {
    if (state.isLoading) return const LoadingView();
    if (state.error != null) {
      return ErrorView(
        title: 'Category data cannot be loaded.',
        description: state.error!.replaceAll('Exception: ', ''),
        onRetry: () => ref
            .read(categoryListProvider.notifier)
            .loadCategories(isRefresh: true),
      );
    }
    if (state.categories.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'No categories found',
        description: 'No categories match your search criteria.',
        actionLabel: 'Reset Filters',
        onActionPressed: () {
          _searchController.clear();
          ref.read(categoryListProvider.notifier).search('');
        },
      );
    }

    return Column(
      children: [
        Expanded(child: _buildTable(context, theme, state.categories)),
        const Divider(height: 1),
        _buildPagination(context, theme, state),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    ThemeData theme,
    List<CategoryItem> items,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                horizontalMargin: 24,
                columnSpacing: 24,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('Category Name')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.map((item) {
                  final bool isActive = item.status == 'ACTIVE';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.categoryName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(theme, item.status)),
                      DataCell(_buildActionButtons(context, theme, item)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final bool isActive = status == 'ACTIVE';
    return Text(
      isActive ? 'Active' : 'Deactive',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isActive
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    CategoryItem item,
  ) {
    final isActive = item.status == 'ACTIVE';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          tooltip: 'Edit Category',
          onPressed: () async {
            final result = await context.push(
              '/stock/categories/edit/${item.categoryNumber}',
            );
            if (result == true && context.mounted) {
              ref
                  .read(categoryListProvider.notifier)
                  .loadCategories(isRefresh: true);
            }
          },
        ),
        IconButton(
          icon: Icon(
            isActive ? Icons.toggle_on : Icons.toggle_off,
            color: isActive ? theme.colorScheme.primary : Colors.grey,
            size: 28,
          ),
          tooltip: isActive ? 'Deactivate Category' : 'Activate Category',
          onPressed: () => _confirmToggleStatus(context, theme, item),
        ),
      ],
    );
  }

  Future<void> _confirmToggleStatus(
    BuildContext context,
    ThemeData theme,
    CategoryItem item,
  ) async {
    final isActive = item.status == 'ACTIVE';
    final newStatus = isActive ? 'INACTIVE' : 'ACTIVE';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Deactivate Category?' : 'Activate Category?'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${item.categoryName}?'
              : 'Are you sure you want to activate ${item.categoryName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isActive ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(categoryListProvider.notifier)
            .updateCategoryStatus(item.categoryNumber, newStatus);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category status has been updated successfully.'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category status cannot be updated.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildPagination(
    BuildContext context,
    ThemeData theme,
    CategoryListState state,
  ) {
    final currentPage = state.currentPage + 1; // 1-indexed for display
    final totalPages = state.totalPages == 0 ? 1 : state.totalPages;

    List<int> pagesToShow = [];
    if (totalPages <= 5) {
      pagesToShow = List.generate(totalPages, (i) => i + 1);
    } else {
      if (currentPage <= 3) {
        pagesToShow = [1, 2, 3, -1, totalPages];
      } else if (currentPage >= totalPages - 2) {
        pagesToShow = [1, -1, totalPages - 2, totalPages - 1, totalPages];
      } else {
        pagesToShow = [
          1,
          -1,
          currentPage - 1,
          currentPage,
          currentPage + 1,
          -1,
          totalPages,
        ];
      }
    }

    List<Widget> pageBoxes = [];

    for (final page in pagesToShow) {
      if (page == -1) {
        pageBoxes.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '...',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      } else {
        final isSelected = page == currentPage;
        pageBoxes.add(
          InkWell(
            onTap: () {
              ref.read(categoryListProvider.notifier).goToPage(page - 1);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pageBoxes,
          ),
        ),
      ),
    );
  }
}
