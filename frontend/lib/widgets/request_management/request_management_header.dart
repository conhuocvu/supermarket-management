import 'package:flutter/material.dart';

class RequestManagementHeader extends StatelessWidget {
  final bool isCompact;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const RequestManagementHeader({
    super.key,
    required this.isCompact,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review leave and shift change requests submitted by staff.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );

    final refreshButton = SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : () => onRefresh(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleSection, const SizedBox(height: 16), refreshButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 24),
        refreshButton,
      ],
    );
  }
}
