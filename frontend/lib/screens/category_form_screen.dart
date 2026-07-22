import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/category_item.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final int? categoryNumber;

  const CategoryFormScreen({super.key, this.categoryNumber});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _internalNotesController = TextEditingController();

  int? _selectedParentCategory;
  List<CategoryItem> _availableCategories = [];
  String? _status;

  bool get isEditMode => widget.categoryNumber != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: isEditMode ? 'EDIT CATEGORY' : 'ADD CATEGORY',
            actions: [],
            breadcrumbs: [
              'Inventory',
              'Categories',
              isEditMode ? 'Edit Category' : 'Add Category',
            ],
          );
    });
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getCategories(page: 0, size: 1000);
      final items = response['data']['items'] as List<dynamic>;
      _availableCategories = items
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .where((c) => c.categoryNumber != widget.categoryNumber)
          .toList();

      if (widget.categoryNumber != null) {
        final categoryMap = await _apiService.getCategoryById(widget.categoryNumber!);
        final category = CategoryItem.fromJson(categoryMap);
        _nameController.text = category.categoryName;
        _descriptionController.text = category.description ?? '';
        _internalNotesController.text = category.internalNotes ?? '';
        _selectedParentCategory = category.parentCategoryNumber;
        _status = category.status;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct invalid category information.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'categoryName': _nameController.text.trim(),
        'parentCategoryNumber': _selectedParentCategory,
        'description': _descriptionController.text.trim(),
        'internalNotes': _internalNotesController.text.trim(),
        'status': _status ?? 'ACTIVE',
      };

      if (widget.categoryNumber == null) {
        await _apiService.createCategory(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category has been saved successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } else {
        await _apiService.updateCategory(widget.categoryNumber!, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category has been updated successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoryNumber == null
                  ? 'Category cannot be saved. $e'
                  : 'Category cannot be updated. $e',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final customInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onPressed: () => context.pop(false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Category Name & Parent Category
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryNameField(customInputDecoration),
                            const SizedBox(height: 20),
                            _buildParentCategoryField(customInputDecoration),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCategoryNameField(customInputDecoration)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildParentCategoryField(customInputDecoration)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Row 2: Description
                  _buildFormField(
                    label: 'DESCRIPTION',
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: customInputDecoration.copyWith(
                        hintText: '[Provide a brief overview of the category purposes]',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Row 3: Internal Notes
                  _buildFormField(
                    label: 'INTERNAL NOTES (VISIBLE TO STAFF ONLY)',
                    child: TextFormField(
                      controller: _internalNotesController,
                      maxLines: 3,
                      decoration: customInputDecoration.copyWith(
                        hintText: '[Enter any confidential or administrative notes here]',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Row 4: Action Buttons (SAVE CATEGORY & CANCEL)
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _isSaving ? null : _saveCategory,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SAVE CATEGORY',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => context.pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          side: const BorderSide(color: Color(0xFF1F2937), width: 1.5),
                          foregroundColor: const Color(0xFF1F2937),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNameField(InputDecoration customInputDecoration) {
    return _buildFormField(
      label: 'CATEGORY NAME',
      child: TextFormField(
        controller: _nameController,
        decoration: customInputDecoration.copyWith(
          hintText: '[Enter Category Name Here]',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Category Name is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildParentCategoryField(InputDecoration customInputDecoration) {
    return _buildFormField(
      label: 'PARENT CATEGORY',
      child: DropdownButtonFormField<int?>(
        initialValue: _selectedParentCategory,
        decoration: customInputDecoration.copyWith(
          hintText: '[Select Parent Category]',
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('None (Root Category)'),
          ),
          ..._availableCategories.map((cat) {
            return DropdownMenuItem<int?>(
              value: cat.categoryNumber,
              child: Text(cat.categoryName),
            );
          }),
        ],
        onChanged: (val) {
          setState(() {
            _selectedParentCategory = val;
          });
        },
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
