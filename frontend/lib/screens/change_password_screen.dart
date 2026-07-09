import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

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

  // Real-time checklist validation
  bool get _hasMinLength => _newPassword.length >= 8;
  bool get _hasUppercase => _newPassword.contains(RegExp(r'[A-Z]'));
  bool get _hasSpecialChar => _newPassword.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _matchesExactly => _newPassword.isNotEmpty && _newPassword == _confirmPassword;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Change Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                      onChanged: (val) => _currentPassword = val,
                      toggleVisibility: () {
                        setState(() {
                          _obscureCurrent = !_obscureCurrent;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter current password';
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
                        if (val == null || val.isEmpty) return 'Please enter new password';
                        if (!_hasMinLength || !_hasUppercase || !_hasSpecialChar) {
                          return 'Password does not meet requirements';
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
                        if (val == null || val.isEmpty) return 'Please confirm new password';
                        if (val != _newPassword) return 'Passwords do not match';
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
                        Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 20),
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
                    _buildChecklistItem('Minimum 8 characters long', _hasMinLength, theme),
                    const SizedBox(height: 8),
                    _buildChecklistItem('Include at least one uppercase letter', _hasUppercase, theme),
                    const SizedBox(height: 8),
                    _buildChecklistItem('Include one special character (!@#\$)', _hasSpecialChar, theme),
                    const SizedBox(height: 8),
                    _buildChecklistItem('Passwords must match exactly', _matchesExactly, theme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Help Info Bento
              BentoCard(
                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: theme.colorScheme.primary),
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
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Submit request log entry for changing password
                      final newRequest = RequestItem(
                        id: 'REQ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        type: RequestType.leave, // Use leave or custom details
                        title: 'Credentials Update',
                        description: 'Updated account login password securely',
                        status: RequestStatus.resolved,
                        submissionDate: DateTime.now(),
                        timeline: [
                          TimelineEvent(
                            title: 'Password Change Initiated',
                            description: 'Client update triggered',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Resolved',
                            description: 'Credentials database synchronized successfully',
                            timestamp: DateTime.now(),
                          ),
                        ],
                        details: {
                          'initiatedBy': appState.currentUser.name,
                          'ipAddress': '192.168.1.104',
                          'status': 'Secured',
                          'currentPasswordLength': _currentPassword.length,
                        },
                      );

                      appState.addRequest(newRequest);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Password changed successfully!'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );

                      Navigator.of(context).pop();
                    }
                  },
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
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
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
          color: isMet ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMet ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
