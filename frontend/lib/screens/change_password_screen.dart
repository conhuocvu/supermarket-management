import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/bento_card.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  // Real-time checklist validation
  bool get _hasMinLength => _newPassword.length >= 8;
  bool get _hasUppercase => _newPassword.contains(RegExp(r'[A-Z]'));
  bool get _hasSpecialChar =>
      _newPassword.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _isDifferentFromCurrent =>
      _newPassword.isNotEmpty && _newPassword != _currentPassword;
  bool get _matchesExactly =>
      _newPassword.isNotEmpty && _newPassword == _confirmPassword;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final theme = Theme.of(context);
    final client = Supabase.instance.client;
    final email = client.auth.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No signed-in user found.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Verify the current password before allowing the update
      await client.auth.signInWithPassword(
        email: email,
        password: _currentPassword,
      );
      await client.auth.updateUser(UserAttributes(password: _newPassword));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully!'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase().contains(
            'invalid login credentials',
          )
          ? 'Current password is incorrect.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          'Change Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Context Header text
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                    child: Text(
                      'Secure your account by updating your credentials. We recommend a strong, unique password.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Inputs Bento Card
                  BentoCard(
                    child: Column(
                      children: [
                        // Current Password
                        _buildPasswordField(
                          label: 'Current Password',
                          obscureText: _obscureCurrent,
                          onChanged: (val) {
                            setState(() {
                              _currentPassword = val;
                            });
                          },
                          toggleVisibility: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // New Password
                        _buildPasswordField(
                          label: 'New Password',
                          obscureText: _obscureNew,
                          onChanged: (val) {
                            setState(() {
                              _newPassword = val;
                            });
                          },
                          toggleVisibility: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter new password';
                            }
                            if (!_hasMinLength ||
                                !_hasUppercase ||
                                !_hasSpecialChar) {
                              return 'Password does not meet requirements';
                            }
                            if (!_isDifferentFromCurrent) {
                              return 'New password must differ from current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        _buildPasswordField(
                          label: 'Confirm New Password',
                          obscureText: _obscureConfirm,
                          onChanged: (val) {
                            setState(() {
                              _confirmPassword = val;
                            });
                          },
                          toggleVisibility: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm new password';
                            }
                            if (val != _newPassword) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Checklist Bento Card
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Security Checklist',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildChecklistItem(
                          'Minimum 8 characters long',
                          _hasMinLength,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildChecklistItem(
                          'Include at least one uppercase letter',
                          _hasUppercase,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildChecklistItem(
                          'Include one special character (!@#\$)',
                          _hasSpecialChar,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildChecklistItem(
                          'Different from current password',
                          _isDifferentFromCurrent,
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildChecklistItem(
                          'Passwords must match exactly',
                          _matchesExactly,
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help Info Bento
                  BentoCard(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forgot your old password?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Contact IT support for a manual reset.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool obscureText,
    required ValueChanged<String> onChanged,
    required VoidCallback toggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.2,
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
              onPressed: toggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String label, bool isMet, ThemeData theme) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMet
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
