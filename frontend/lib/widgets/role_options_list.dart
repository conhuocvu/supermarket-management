import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/widgets/shared/app_card.dart';

class RoleOptionsList extends StatelessWidget {
  final List<Map<String, dynamic>> roleOptions;
  final String? selectedRole;
  final ValueChanged<String> onRoleSelected;

  const RoleOptionsList({
    super.key,
    required this.roleOptions,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final opt in roleOptions) ...[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: selectedRole == opt['role'] ? Colors.white : AppTheme.surface,
            border: Border.all(
              color: selectedRole == opt['role'] ? AppTheme.primary : AppTheme.border,
              width: selectedRole == opt['role'] ? 2 : 1,
            ),
            onTap: () => onRoleSelected(opt['role'] as String),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: opt['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opt['icon'] as IconData, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt['description'] as String,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedRole == opt['role'] ? AppTheme.primary : AppTheme.border,
                      width: 2,
                    ),
                  ),
                  child: selectedRole == opt['role']
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
