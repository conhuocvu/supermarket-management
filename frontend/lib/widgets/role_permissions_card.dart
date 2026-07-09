import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class RolePermissionsCard extends StatelessWidget {
  final String? selectedRole;
  final Map<String, List<String>> rolePermissions;

  const RolePermissionsCard({
    super.key,
    required this.selectedRole,
    required this.rolePermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRole == null) return const SizedBox.shrink();

    final permissions = rolePermissions[selectedRole] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Permissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final perm in permissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      perm,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
