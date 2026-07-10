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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isEdit = widget.categoryNumber != null;
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: isEdit ? 'Edit Category' : 'Add New Category',
            actions: [],
            breadcrumbs: [
              'Inventory',
              'Categories',
              isEdit ? 'Edit Category' : 'Add Category',
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
          .where((c) => c.categoryNumber != widget.categoryNumber) // prevent self as parent
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
    final isEdit = widget.categoryNumber != null;

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Category Name',
                          child: TextFormField(
                            controller: _nameController,
                            decoration: inputDecorationTheme.copyWith(
                              hintText: 'Enter Category Name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Category Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: _buildFormField(
                          label: 'Parent Category',
                          child: DropdownMenu<int?>(
                            initialSelection: _selectedParentCategory,
                            expandedInsets: EdgeInsets.zero,
                            inputDecorationTheme: InputDecorationTheme(
                              filled: inputDecorationTheme.filled,
                              fillColor: inputDecorationTheme.fillColor,
                              contentPadding: inputDecorationTheme.contentPadding,
                              border: inputDecorationTheme.border,
                              focusedBorder: inputDecorationTheme.focusedBorder,
                              errorBorder: inputDecorationTheme.errorBorder,
                              focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                            ),
                            hintText: 'Select Parent Category',
                            enableFilter: true,
                            enableSearch: true,
                            onSelected: (int? value) {
                              setState(() {
                                _selectedParentCategory = value;
                              });
                            },
                            dropdownMenuEntries: [
                              const DropdownMenuEntry<int?>(
                                value: null,
                                label: 'None (Root Category)',
                              ),
                              ..._availableCategories.map((cat) {
                                return DropdownMenuEntry<int?>(
                                  value: cat.categoryNumber,
                                  label: cat.categoryName,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFormField(
                    label: 'Description',
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: inputDecorationTheme.copyWith(
                        hintText: 'Provide a brief overview of the category purposes',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFormField(
                    label: 'Internal Notes (Visible to Staff Only)',
                    child: TextFormField(
                      controller: _internalNotesController,
                      maxLines: 3,
                      decoration: inputDecorationTheme.copyWith(
                        hintText: 'Enter any confidential or administrative notes here',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _isSaving ? null : _saveCategory,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
                            : const Text('Save Category'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        ),
                        child: const Text('Cancel'),
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


  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
