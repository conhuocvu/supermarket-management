import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
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

class _CategoryListScreenState
    extends ConsumerState<CategoryListScreen> {
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
              _buildFilterHeader(context, state),
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
                  child: _buildBody(state),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(CategoryListState state) {
    if (state.isLoading) return const LoadingView();
    if (state.error != null) {
      return ErrorView(
        title: 'Category data cannot be loaded.',
        description: state.error!.replaceAll('Exception: ', ''),
        onRetry: () =>
            ref.read(categoryListProvider.notifier).loadCategories(isRefresh: true),
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
        Expanded(child: _buildTable(context, state.categories)),
        const Divider(height: 1),
        _buildPagination(context, state),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context, CategoryListState state) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        Widget searchField = SizedBox(
          height: 48,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(categoryListProvider.notifier).search('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
            onSubmitted: (val) {
              ref.read(categoryListProvider.notifier).search(val);
            },
          ),
        );

        Widget addBtn = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () async {
              final result = await context.push('/stock/categories/add');
              if (result == true && context.mounted) {
                ref.read(categoryListProvider.notifier).loadCategories(isRefresh: true);
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Category'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 16),
              addBtn,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 16),
              addBtn,
            ],
          );
        }
      },
    );
  }

  Widget _buildTable(BuildContext context, List<CategoryItem> items) {
    final theme = Theme.of(context);
    
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
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Parent Name')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.map((item) {
                  final bool isActive = item.status == 'ACTIVE';
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (!isActive) {
                          return theme.colorScheme.onSurface.withValues(alpha: 0.05);
                        }
                        return null; // Use default
                      },
                    ),
                    cells: [
                      DataCell(Text('#${item.categoryNumber}')),
                      DataCell(Text(
                        item.categoryName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isActive ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      )),
                      DataCell(Text(item.parentCategoryName ?? '-')),
                      DataCell(Text(item.description ?? '-')),
                      DataCell(_buildStatusBadge(item.status)),
                      DataCell(
                        _buildActionButtons(context, item),
                      ),
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

  Widget _buildStatusBadge(String status) {
    final bool isActive = status == 'ACTIVE';
    final color = isActive ? AppTheme.primaryColor : AppTheme.errorColor;
    final bgColor = isActive 
        ? AppTheme.primaryColor.withValues(alpha: 0.1) 
        : AppTheme.errorColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CategoryItem item) {
    final isActive = item.status == 'ACTIVE';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
          tooltip: 'Edit Category',
          onPressed: () async {
            final result = await context.push('/stock/categories/edit/${item.categoryNumber}');
            if (result == true && context.mounted) {
              ref.read(categoryListProvider.notifier).loadCategories(isRefresh: true);
            }
          },
        ),
        IconButton(
          icon: Icon(
            isActive ? Icons.toggle_on : Icons.toggle_off,
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            size: 28,
          ),
          tooltip: isActive ? 'Deactivate Category' : 'Activate Category',
          onPressed: () => _confirmToggleStatus(context, item),
        ),
      ],
    );
  }
  
  Future<void> _confirmToggleStatus(BuildContext context, CategoryItem item) async {
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
              backgroundColor: isActive ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ref.read(categoryListProvider.notifier)
            .updateCategoryStatus(item.categoryNumber, newStatus);
            
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category status has been updated successfully.'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category status cannot be updated.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildPagination(BuildContext context, CategoryListState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing page ${state.currentPage + 1} of ${state.totalPages} (${state.totalItems} items)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 0
                    ? () => ref.read(categoryListProvider.notifier).loadPreviousPage()
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < state.totalPages - 1
                    ? () => ref.read(categoryListProvider.notifier).loadNextPage()
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
