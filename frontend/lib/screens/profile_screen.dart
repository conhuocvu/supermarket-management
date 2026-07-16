import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const int _maxAvatarBytes = 2 * 1024 * 1024; // keep in sync with bucket limit
  static const _allowedAvatarTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _employeeIdController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _postalController;
  // _hasChanges is a computed getter — no bool field needed
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final profile = authState.profile;

    _employeeIdController =
        TextEditingController(text: profile?.userId ?? '');
    _fullNameController =
        TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _emailController =
        TextEditingController(text: authState.user?.email ?? '');
    _postalController = TextEditingController(text: profile?.address ?? '');

    // Trigger rebuild on text change so the computed _hasChanges getter
    // re-evaluates and the Save button reflects the actual diff.
    for (final c in [_fullNameController, _phoneController, _postalController]) {
      c.addListener(() => setState(() {}));
    }
  }

  /// True when the current field values differ from the profile stored in state.
  /// This prevents the Save button staying active after the user reverts edits.
  bool get _hasChanges {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return false;
    final nameDiff =
        _fullNameController.text.trim() != profile.fullName.trim();
    final phoneDiff =
        _phoneController.text.replaceAll(RegExp(r'[\s-]'), '') !=
        profile.phone.replaceAll(RegExp(r'[\s-]'), '');
    final addressDiff =
        _postalController.text.trim() != (profile.address?.trim() ?? '');
    return nameDiff || phoneDiff || addressDiff;
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- Validation rules -----------------------------------------------------

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name';
    if (name.length < 2) return 'Full name must be at least 2 characters';
    if (name.length > 100) return 'Full name must be under 100 characters';
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return 'Full name cannot contain numbers';
    }
    if (!RegExp(r"^[\p{L}\s.'-]+$", unicode: true).hasMatch(name)) {
      return 'Full name contains invalid characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (phone.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^(\+84|0)\d{9,10}$').hasMatch(phone)) {
      return 'Enter a valid phone number (e.g. 0912345678 or +84912345678)';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final address = value?.trim() ?? '';
    if (address.length > 255) {
      return 'Address must be under 255 characters';
    }
    return null;
  }

  // --- Persistence ----------------------------------------------------------

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fix the highlighted fields first.', isError: true);
      return;
    }
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      // Issue #1 fix: route the update through Spring Boot instead of writing
      // directly to Supabase from the client.
      final updated = await ApiService().updateProfile(
        userId: userId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'[\s-]'), ''),
        address: _postalController.text.trim().isEmpty
            ? null
            : _postalController.text.trim(),
      );

      // Issue #5 fix: use the returned ProfileDTO to update state directly
      // without firing an extra GET request.
      ref.read(authProvider.notifier).updateProfileState(updated);

      if (!mounted) return;
      // Rebuild so the computed _hasChanges getter re-evaluates to false.
      setState(() {});
      _showSnack('Profile changes saved successfully!');
    } catch (e) {
      _showSnack('Failed to save profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _isUploadingAvatar) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    final contentType = _allowedAvatarTypes[ext];
    if (contentType == null) {
      _showSnack('Only JPG, PNG or WebP images are allowed.', isError: true);
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > _maxAvatarBytes) {
      _showSnack('Image is too large. Maximum size is 2MB.', isError: true);
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      // Evict the old avatar from Flutter's image cache so the new one loads
      final oldAvatarUrl = ref.read(authProvider).profile?.avatarUrl;
      if (oldAvatarUrl != null) {
        imageCache.evict(NetworkImage(oldAvatarUrl));
      }

      await ApiService().uploadAvatar(userId, picked);
      await ref.read(authProvider.notifier).refreshProfile();
      _showSnack('Profile photo updated!');
    } catch (e) {
      _showSnack('Failed to upload photo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // --- UI ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Account Settings',
            breadcrumbs: ['Account', 'Profile'],
          );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          child: _buildLeftColumn(context, theme),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column – fills remaining space, scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildRightColumn(context, theme),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildLeftColumn(context, theme),
                        const SizedBox(height: 24),
                        _buildRightColumn(context, theme),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String fullName, String? avatarUrl) {
    final initials = fullName.isNotEmpty
        ? fullName
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  initials,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (_isUploadingAvatar)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _pickAndUploadAvatar,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context, ThemeData theme) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final fullName = profile?.fullName ?? authState.user?.email ?? 'User';
    final isActive = (profile?.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';
    final statusLabel = isActive ? 'Active' : (profile?.status ?? 'Unknown');
    final statusColor = isActive ? Colors.green : Colors.orange;

    final joinedDate = profile != null
        ? DateFormat('MMM d, y').format(profile.createdAt)
        : '—';
    final lastSignIn = authState.user?.lastSignInAt;
    final lastLogin = lastSignIn != null
        ? DateFormat('MMM d, y HH:mm')
            .format(DateTime.parse(lastSignIn).toLocal())
        : '—';
    final employeeId = profile != null && profile.userId.length >= 8
        ? 'EMP-${profile.userId.substring(0, 8).toUpperCase()}'
        : '—';

    return Column(
      children: [
        // Avatar Card
        BentoCard(
          child: Column(
            children: [
              _buildAvatar(theme, fullName, profile?.avatarUrl),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Text(
                  _isUploadingAvatar ? 'Uploading...' : 'Change Photo',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'JPG, PNG or WebP — max 2MB',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusRow(context, 'Employee ID', employeeId),
              const SizedBox(height: 8),
              _buildStatusRow(context, 'Role', profile?.roleName ?? '—'),
              const SizedBox(height: 8),
              _buildStatusRow(context, 'Joined Date', joinedDate),
              const SizedBox(height: 8),
              _buildStatusRow(context, 'Last Login', lastLogin),
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
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
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
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildRightColumn(BuildContext context, ThemeData theme) {
    return BentoCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
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
                        controller: _employeeIdController,
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
                        validator: _validateFullName,
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
                    controller: _employeeIdController,
                    readOnly: true,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Full Name',
                    controller: _fullNameController,
                    required: true,
                    validator: _validateFullName,
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
                        validator: _validatePhone,
                        helperText: 'Format: 0912345678 or +84912345678',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        context,
                        label: 'Email Address',
                        controller: _emailController,
                        readOnly: true,
                        required: false,
                        suffix: const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        helperText: 'Managed by your login account',
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
                    validator: _validatePhone,
                    helperText: 'Format: 0912345678 or +84912345678',
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    context,
                    label: 'Email Address',
                    controller: _emailController,
                    readOnly: true,
                    required: false,
                    suffix: const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    helperText: 'Managed by your login account',
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
              validator: _validateAddress,
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
                    context.push('/change-password');
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _hasChanges && !_isSaving
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value) {
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
    FormFieldValidator<String>? validator,
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
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          validator: readOnly ? null : validator,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            fillColor: readOnly
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)
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
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
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
