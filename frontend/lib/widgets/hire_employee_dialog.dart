import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_button.dart';
import 'package:frontend/widgets/shared/app_text_field.dart';

class HireEmployeeDialog extends ConsumerStatefulWidget {
  const HireEmployeeDialog({super.key});

  @override
  ConsumerState<HireEmployeeDialog> createState() => _HireEmployeeDialogState();
}

class _HireEmployeeDialogState extends ConsumerState<HireEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedRole = 'CASHIER';
  bool _submitting = false;
  Map<String, String>? _validationErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _validationErrors = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final result = await ref.read(employeesProvider.notifier).hireEmployee(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hired new employee successfully!'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      final err = result.error;
      if (err != null && err.code.name == 'VALIDATION' && err.fieldErrors != null) {
        setState(() => _validationErrors = err.fieldErrors);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err?.userMessage ?? 'Failed to hire employee.'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hire New Employee', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Họ và tên',
                hint: 'Nguyễn Văn A',
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập họ tên' : null,
              ),
              if (_validationErrors?.containsKey('name') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['name']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'a@supermarket.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập email' : null,
              ),
              if (_validationErrors?.containsKey('email') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['email']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Số điện thoại',
                hint: '0987654321',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập số điện thoại' : null,
              ),
              if (_validationErrors?.containsKey('phone') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['phone']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'Chi nhánh / Khu vực làm việc',
                hint: 'Downtown Branch - Zone A',
                controller: _locationController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập vị trí' : null,
              ),
              if (_validationErrors?.containsKey('location') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['location']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Chức vụ ban đầu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                  DropdownMenuItem(value: 'CASHIER', child: Text('Cashier')),
                  DropdownMenuItem(value: 'INVENTORY_STAFF', child: Text('Inventory Staff')),
                  DropdownMenuItem(value: 'SALES_ASSOCIATE', child: Text('Sales Associate')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              if (_validationErrors?.containsKey('role') ?? false) ...[
                const SizedBox(height: 4),
                Text(_validationErrors!['role']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        AppButton(
          text: 'Hire',
          isLoading: _submitting,
          onPressed: _submit,
          width: 100,
        ),
      ],
    );
  }
}
