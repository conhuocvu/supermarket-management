import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _postalController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _fullNameController = TextEditingController(text: appState.currentUser.name);
    _phoneController = TextEditingController(text: appState.currentUser.phone);
    _emailController = TextEditingController(text: appState.currentUser.email);
    _postalController = TextEditingController(
        text: '124 High Street, Suite 400\nLondon, SW1E 5RS\nUnited Kingdom');

    for (final c in [
      _fullNameController,
      _phoneController,
      _emailController,
      _postalController
    ]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Account Settings',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your personal information and account preferences',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column – fixed width, scrollable
                    SizedBox(
                      width: 270,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildLeftColumn(context, appState, theme),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column – fills remaining space, scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildRightColumn(context, appState, theme),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildLeftColumn(context, appState, theme),
                      const SizedBox(height: 24),
                      _buildRightColumn(context, appState, theme),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(
      BuildContext context, AppState appState, ThemeData theme) {
    return Column(
      children: [
        // Avatar Card
        BentoCard(
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(appState.currentUser.imageUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child:
                          const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Change Photo',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Account Status
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCOUNT STATUS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusRow(context, 'Employee ID', 'EMP-82910'),
              const SizedBox(height: 8),
              _buildStatusRow(context, 'Joined Date', 'Jan 12, 2022'),
              const SizedBox(height: 8),
              _buildStatusRow(context, 'Last Login', '2 hours ago'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2FA Card
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Two-Factor Authentication',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Keep your account secure by enabling 2FA for all logins.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {},
                child: Text(
                  'Setup Security',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security badges
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'ISO 27001 Certified',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'End-to-End Encrypted',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightColumn(
      BuildContext context, AppState appState, ThemeData theme) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(Icons.security_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'All changes are logged for security',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Employee ID + Full Name
          LayoutBuilder(builder: (ctx, constraints) {
            final useRow = constraints.maxWidth >= 500;
            if (useRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Employee ID',
                      controller: TextEditingController(text: 'EMP-82910'),
                      readOnly: true,
                      required: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Full Name',
                      controller: _fullNameController,
                      required: true,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildFormField(
                  context,
                  label: 'Employee ID',
                  controller: TextEditingController(text: 'EMP-82910'),
                  readOnly: true,
                  required: false,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  context,
                  label: 'Full Name',
                  controller: _fullNameController,
                  required: true,
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Phone + Email
          LayoutBuilder(builder: (ctx, constraints) {
            final useRow = constraints.maxWidth >= 500;
            if (useRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Phone Number',
                      controller: _phoneController,
                      required: true,
                      suffix: const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      helperText: 'Number verified via SMS',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormField(
                      context,
                      label: 'Email Address',
                      controller: _emailController,
                      required: true,
                      suffix: const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildFormField(
                  context,
                  label: 'Phone Number',
                  controller: _phoneController,
                  required: true,
                  suffix: const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                  helperText: 'Number verified via SMS',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  context,
                  label: 'Email Address',
                  controller: _emailController,
                  required: true,
                  suffix: const Icon(Icons.check_circle,
                      color: Colors.green, size: 18),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Postal Address
          _buildFormField(
            context,
            label: 'Postal Address',
            controller: _postalController,
            maxLines: 3,
            required: false,
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save Changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: _hasChanges
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                onPressed: _hasChanges
                    ? () {
                        setState(() => _hasChanges = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Profile changes saved successfully!'),
                            backgroundColor: theme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool readOnly = false,
    int maxLines = 1,
    Widget? suffix,
    String? helperText,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: theme.colorScheme.error),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            fillColor: readOnly
                ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                : theme.colorScheme.surface,
            filled: true,
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            helperText: helperText,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontSize: 10,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
