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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onKeywordChanged,
            decoration: InputDecoration(
              hintText: 'Search by employee name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _FilterGroup(
            title: 'Request type',
            values: const {
              'ALL': 'All',
              'LEAVE': 'Leave',
              'SHIFT_CHANGE': 'Shift Change',
            },
            selectedValue: state.requestType,
            onSelected: onRequestTypeSelected,
          ),
          const SizedBox(height: 16),
          _FilterGroup(
            title: 'Status',
            values: const {
              'ALL': 'All',
              'PENDING': 'Pending',
              'APPROVED': 'Approved',
              'REJECTED': 'Rejected',
            },
            selectedValue: state.status,
            onSelected: onStatusSelected,
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final Map<String, String> values;
  final String selectedValue;
  final Future<void> Function(String) onSelected;

  const _FilterGroup({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.entries.map((entry) {
            final selected = selectedValue == entry.key;

            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onSelected(entry.key),
              showCheckmark: false,
              selectedColor: colorScheme.primary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              side: BorderSide(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              labelStyle: TextStyle(
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
