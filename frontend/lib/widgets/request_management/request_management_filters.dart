import 'package:flutter/material.dart';

import '../../providers/staff_request_provider.dart';

class RequestManagementFilters extends StatelessWidget {
  final TextEditingController searchController;
  final StaffRequestState state;
  final void Function(String) onKeywordChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function(String) onRequestTypeSelected;
  final Future<void> Function(String) onStatusSelected;

  const RequestManagementFilters({
    super.key,
    required this.searchController,
    required this.state,
    required this.onKeywordChanged,
    required this.onClearSearch,
    required this.onRequestTypeSelected,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<DropdownMenuItem<String>> typeItems = const [
      DropdownMenuItem(value: 'ALL', child: Text('All Types')),
      DropdownMenuItem(value: 'LEAVE', child: Text('Leave')),
      DropdownMenuItem(value: 'SHIFT_CHANGE', child: Text('Shift Change')),
      DropdownMenuItem(value: 'CLEARANCE', child: Text('Discount')),
      DropdownMenuItem(value: 'PURCHASE', child: Text('Purchase')),
    ];

    final List<DropdownMenuItem<String>> statusItems = const [
      DropdownMenuItem(value: 'ALL', child: Text('All Status')),
      DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
      DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
      DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
    ];

    final searchWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Request',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: searchController,
            onChanged: onKeywordChanged,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search by employee name',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
      ],
    );

    Widget buildDropdown<T>({
      required String label,
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      );
    }

    final typeWidget = buildDropdown<String>(
      label: 'Request type',
      value: state.requestType,
      items: typeItems,
      onChanged: (v) => onRequestTypeSelected(v ?? 'ALL'),
    );

    final statusWidget = buildDropdown<String>(
      label: 'Status',
      value: state.status,
      items: statusItems,
      onChanged: (v) => onStatusSelected(v ?? 'ALL'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 750;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: searchWidget),
              const SizedBox(width: 16),
              Expanded(child: typeWidget),
              const SizedBox(width: 16),
              Expanded(child: statusWidget),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchWidget,
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: typeWidget),
                const SizedBox(width: 12),
                Expanded(child: statusWidget),
              ],
            ),
          ],
        );
      },
    );
  }
}
