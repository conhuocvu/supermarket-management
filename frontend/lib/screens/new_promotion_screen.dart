import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/promotion.dart';
import 'package:frontend/providers/promotion_provider.dart';
import 'package:frontend/widgets/shared/app_text_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/core/errors/app_error.dart';
import 'package:frontend/widgets/shared/smart_image.dart';

class NewPromotionScreen extends ConsumerStatefulWidget {
  final int? promotionId;

  const NewPromotionScreen({super.key, this.promotionId});

  @override
  ConsumerState<NewPromotionScreen> createState() => _NewPromotionScreenState();
}

class _NewPromotionScreenState extends ConsumerState<NewPromotionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  
  String _priority = 'MEDIUM';
  String _discountType = 'PERCENTAGE';
  List<String> _targetCategories = [];
  List<String> _targetProducts = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _imageUrl = '';
  String _visibility = 'Storewide & Online';

  bool _isInitialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  void _initializeFields(Promotion promotion) {
    if (_isInitialized) return;
    _nameController.text = promotion.name;
    _codeController.text = promotion.code;
    _descriptionController.text = promotion.description;
    _priority = promotion.priority;
    _discountType = promotion.discountType;
    _discountValueController.text = promotion.discountValue.toString();
    _targetCategories = List.from(promotion.targetCategories);
    _targetProducts = List.from(promotion.targetProducts);
    _startDate = promotion.startDate;
    _endDate = promotion.endDate;
    _imageUrl = promotion.imageUrl;
    _visibility = promotion.visibility;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.promotionId != null;

    if (isEditMode) {
      final promotionAsync = ref.watch(promotionDetailProvider(widget.promotionId!));
      return promotionAsync.when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Edit Promotion')),
          body: ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(promotionDetailProvider(widget.promotionId!)),
          ),
        ),
        data: (promotion) {
          _initializeFields(promotion);
          return _buildFormScaffold(context, 'Edit Promotion');
        },
      );
    } else {
      return _buildFormScaffold(context, 'New Promotion');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.textPrimary, size: 28),
            onPressed: () {},
          ),
        ],
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
                _buildImagePickerSlot(context),
                const SizedBox(height: 24),
                
                // Basic Info
                Text(
                  'Basic Info',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Promotion Name',
                  hint: 'e.g. Weekend Freshness Drive',
                  controller: _nameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Promotion Code',
                  hint: 'e.g. FRESH20',
                  controller: _codeController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Code is required' : null,
                ),
                const SizedBox(height: 16),
                _buildPriorityDropdown(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 24),
                
                // Discount Details
                Text(
                  'Discount Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDiscountTypeToggle(),
                const SizedBox(height: 16),
                AppTextField(
                  label: _discountType == 'PERCENTAGE' ? 'Discount Value (%)' : 'Discount Value (\$)',
                  hint: '0.00',
                  controller: _discountValueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Discount value is required';
                    final d = double.tryParse(val);
                    if (d == null) return 'Must be a valid number';
                    if (d < 0) return 'Cannot be negative';
                    if (_discountType == 'PERCENTAGE' && d > 100) return 'Percentage cannot exceed 100%';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Applicability
                Text(
                  'Applicability',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildCategoriesBuilder(context),
                const SizedBox(height: 16),
                _buildProductsBuilder(context),
                const SizedBox(height: 24),

                // Schedule
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDatePickers(context),
                const SizedBox(height: 32),

                // Actions
                _buildActionButtons(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSlot(BuildContext context) {
    final hasImage = _imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: _pickImageFile,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImage(
                      imageUrl: _imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // overlay tối để icon dễ thấy
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.white, size: 28),
                          SizedBox(height: 6),
                          Text(
                            'Nhấn để đổi ảnh',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 36, color: AppTheme.primary),
                    SizedBox(height: 8),
                    Text(
                      'Chọn ảnh banner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Nhấn để mở hộp thoại chọn ảnh (JPG, PNG, WEBP)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Chọn ảnh banner cho Promotion',
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() {
          _imageUrl = path;
        });
      }
    }
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
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
            value: _priority,
            decoration: const InputDecoration(border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('Low')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
              DropdownMenuItem(value: 'HIGH', child: Text('High')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _priority = val;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter details about the promotion...',
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

  Widget _buildDiscountTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount Type',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _discountType = 'PERCENTAGE'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _discountType == 'PERCENTAGE' ? AppTheme.primary : AppTheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Percentage',
                      style: TextStyle(
                        color: _discountType == 'PERCENTAGE' ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _discountType = 'FIXED_AMOUNT'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _discountType == 'FIXED_AMOUNT' ? AppTheme.primary : AppTheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Fixed Amount',
                      style: TextStyle(
                        color: _discountType == 'FIXED_AMOUNT' ? Colors.white : AppTheme.textSecondary,
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

  Widget _buildCategoriesBuilder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Categories',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._targetCategories.map((c) => Chip(
                  label: Text(c),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _targetCategories.remove(c);
                    });
                  },
                  backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                )),
            InputChip(
              label: const Text('+ Add Category'),
              onPressed: () => _showAddDialog(context, 'Category', (val) {
                setState(() {
                  if (!_targetCategories.contains(val)) _targetCategories.add(val);
                });
              }),
              backgroundColor: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsBuilder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Products',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._targetProducts.map((p) => Chip(
                  label: Text(p),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _targetProducts.remove(p);
                    });
                  },
                  backgroundColor: AppTheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                )),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddDialog(context, 'Product', (val) {
              setState(() {
                if (!_targetProducts.contains(val)) _targetProducts.add(val);
              });
            }),
            icon: const Icon(Icons.add_box_outlined, size: 18),
            label: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Specific Products'),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, String type, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Target $type'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    final DateFormat formatter = DateFormat('MM/dd/yyyy');
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            label: 'Start Date',
            hint: 'mm/dd/yyyy',
            readOnly: true,
            controller: TextEditingController(
              text: _startDate != null ? formatter.format(_startDate!) : '',
            ),
            suffixIcon: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(context, true),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppTextField(
            label: 'End Date',
            hint: 'mm/dd/yyyy',
            readOnly: true,
            controller: TextEditingController(
              text: _endDate != null ? formatter.format(_endDate!) : '',
            ),
            suffixIcon: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(context, false),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 7)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // adjust end date if conflict
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
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
                      Text('Save Promotion'),
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

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start date is required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date is required'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final notifier = ref.read(promotionsProvider.notifier);
    final isEditMode = widget.promotionId != null;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final description = _descriptionController.text.trim();
    final discountValue = double.parse(_discountValueController.text);

    final Result<dynamic> result;
    if (isEditMode) {
      result = await notifier.updatePromotion(
        widget.promotionId!,
        name: name,
        code: code,
        priority: _priority,
        discountType: _discountType,
        discountValue: discountValue,
        description: description,
        targetCategories: _targetCategories,
        targetProducts: _targetProducts,
        startDate: _startDate!,
        endDate: _endDate!,
        imageUrl: _imageUrl,
        visibility: _visibility,
      );
    } else {
      result = await notifier.createPromotion(
        name: name,
        code: code,
        priority: _priority,
        discountType: _discountType,
        discountValue: discountValue,
        description: description,
        targetCategories: _targetCategories,
        targetProducts: _targetProducts,
        startDate: _startDate!,
        endDate: _endDate!,
        imageUrl: _imageUrl,
        visibility: _visibility,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Promotion updated successfully!' : 'Promotion created successfully!'),
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
