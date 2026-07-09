import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/supplier.dart';
import 'package:frontend/providers/supplier_provider.dart';
import 'package:frontend/widgets/shared/app_text_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/core/errors/app_error.dart';

class NewSupplierScreen extends ConsumerStatefulWidget {
  final int? supplierId;

  const NewSupplierScreen({super.key, this.supplierId});

  @override
  ConsumerState<NewSupplierScreen> createState() => _NewSupplierScreenState();
}

class _NewSupplierScreenState extends ConsumerState<NewSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _nextDeliveryController = TextEditingController();
  final _contactValueController = TextEditingController();
  final _notesController = TextEditingController();
  final _certificationController = TextEditingController();

  String _category = 'FRESH PRODUCE';
  String _contactType = 'email';
  String _status = 'Reliable';
  double _onTimeRate = 98.0;
  double _rating = 4.8;

  bool _isInitialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _nextDeliveryController.dispose();
    _contactValueController.dispose();
    _notesController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  void _initializeFields(Supplier supplier) {
    if (_isInitialized) return;
    _codeController.text = supplier.code;
    _nameController.text = supplier.name;
    _nextDeliveryController.text = supplier.nextDelivery;
    _contactValueController.text = supplier.contactValue;
    _notesController.text = supplier.notes;
    _certificationController.text = supplier.certification;
    _category = supplier.category;
    _contactType = supplier.contactType;
    _status = supplier.status;
    _onTimeRate = supplier.onTimeDeliveryRate;
    _rating = supplier.averageRating;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.supplierId != null;

    if (isEditMode) {
      final supplierAsync = ref.watch(supplierDetailProvider(widget.supplierId!));
      return supplierAsync.when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Edit Supplier')),
          body: ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(supplierDetailProvider(widget.supplierId!)),
          ),
        ),
        data: (supplier) {
          _initializeFields(supplier);
          return _buildFormScaffold(context, 'Edit Supplier');
        },
      );
    } else {
      // Auto-generate code for new supplier
      if (!_isInitialized) {
        final randomNum = (100 + (DateTime.now().millisecond % 900));
        _codeController.text = 'SUP-$randomNum';
        _isInitialized = true;
      }
      return _buildFormScaffold(context, 'New Supplier');
    }
  }

  Widget _buildFormScaffold(BuildContext context, String title) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
      body: PageContainer(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Supplier Details
                Text(
                  'Partner Info',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Supplier Code',
                  hint: 'e.g. SUP-082',
                  controller: _codeController,
                  readOnly: widget.supplierId != null, // read-only when editing
                  validator: (val) => val == null || val.trim().isEmpty ? 'Code is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Supplier Name',
                  hint: 'e.g. Global Fresh Farms',
                  controller: _nameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                
                // Certification (Visible only if ORGANIC is selected)
                if (_category == 'ORGANIC') ...[
                  AppTextField(
                    label: 'Certification Details',
                    hint: 'e.g. Certified Organic',
                    controller: _certificationController,
                    validator: (val) => _category == 'ORGANIC' && (val == null || val.trim().isEmpty)
                        ? 'Certification is required for organic category'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                AppTextField(
                  label: 'Next Delivery Schedule',
                  hint: 'e.g. Thursday, 06:00 AM or Daily, 04:30 AM',
                  controller: _nextDeliveryController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Delivery schedule is required' : null,
                ),
                const SizedBox(height: 24),

                // Contact Details
                Text(
                  'Contact Info',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildContactTypeToggle(),
                const SizedBox(height: 16),
                AppTextField(
                  label: _contactType == 'email' ? 'Contact Email' : 'Contact Phone',
                  hint: _contactType == 'email' ? 'info@globalfresh.com' : '+15559876543',
                  controller: _contactValueController,
                  keyboardType: _contactType == 'email' ? TextInputType.emailAddress : TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Contact value is required' : null,
                ),
                const SizedBox(height: 24),

                // Additional details
                Text(
                  'Additional Notes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildNotesField(),
                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
            items: const [
              DropdownMenuItem(value: 'FRESH PRODUCE', child: Text('Produce (FRESH PRODUCE)')),
              DropdownMenuItem(value: 'DAIRY & COLD', child: Text('Dairy (DAIRY & COLD)')),
              DropdownMenuItem(value: 'DRY GOODS', child: Text('Dry Goods (DRY GOODS)')),
              DropdownMenuItem(value: 'ORGANIC', child: Text('Organic (ORGANIC)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _category = val;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _contactType = 'email'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _contactType == 'email' ? AppTheme.primary : AppTheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Email',
                      style: TextStyle(
                        color: _contactType == 'email' ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _contactType = 'phone'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _contactType == 'phone' ? AppTheme.primary : AppTheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Phone',
                      style: TextStyle(
                        color: _contactType == 'phone' ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Partner Notes',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter details, logistics terms, etc...',
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Save Supplier'),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final notifier = ref.read(suppliersProvider.notifier);
    final isEditMode = widget.supplierId != null;

    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final nextDelivery = _nextDeliveryController.text.trim();
    final contactValue = _contactValueController.text.trim();
    final notes = _notesController.text.trim();
    final certification = _category == 'ORGANIC' ? _certificationController.text.trim() : '';

    final Result<Supplier> result;
    if (isEditMode) {
      result = await notifier.updateSupplier(
        widget.supplierId!,
        code: code,
        name: name,
        category: _category,
        nextDelivery: nextDelivery,
        status: _status,
        contactType: _contactType,
        contactValue: contactValue,
        onTimeDeliveryRate: _onTimeRate,
        averageRating: _rating,
        notes: notes,
        certification: certification,
      );
    } else {
      result = await notifier.createSupplier(
        code: code,
        name: name,
        category: _category,
        nextDelivery: nextDelivery,
        status: _status,
        contactType: _contactType,
        contactValue: contactValue,
        onTimeDeliveryRate: _onTimeRate,
        averageRating: _rating,
        notes: notes,
        certification: certification,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Supplier updated successfully!' : 'Supplier created successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error?.userMessage ?? 'An error occurred. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
