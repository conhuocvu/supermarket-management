import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class ProductUpdateForm extends StatefulWidget {
  final String? prefilledSku;

  const ProductUpdateForm({Key? key, this.prefilledSku}) : super(key: key);

  @override
  State<ProductUpdateForm> createState() => _ProductUpdateFormState();
}

class _ProductUpdateFormState extends State<ProductUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedSku;

  // Form Fields
  late String _name;
  late double _costPrice;
  late double _retailPrice;
  late String _aisle;
  late String _shelf;
  late int _shelfCapacity;
  late int _minStockLevel;
  late String _supplier;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedSku = widget.prefilledSku ?? appState.products.first.sku;
    _populateFields(appState);
  }

  void _populateFields(AppState appState) {
    final product = appState.products.firstWhere((p) => p.sku == _selectedSku);
    _name = product.name;
    _costPrice = product.costPrice;
    _retailPrice = product.retailPrice;
    _aisle = product.aisle;
    _shelf = product.shelf;
    _shelfCapacity = product.shelfCapacity;
    _minStockLevel = product.minStockLevel;
    _supplier = product.supplier;
  }

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
          'Suggest Product Update',
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
            children: [
              // Product selection
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Product to Suggest Changes', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSku,
                      decoration: InputDecoration(
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: appState.products.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.sku,
                          child: Text('${p.sku} - ${p.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSku = val;
                            _populateFields(appState);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Specifications Bento Form
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suggested Parameters', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 16),

                    // Name
                    _buildTextField(
                      label: 'Product Name',
                      initialValue: _name,
                      onSaved: (val) => _name = val ?? '',
                    ),
                    const SizedBox(height: 12),

                    // Price Layout
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Cost Price (\$)',
                            initialValue: _costPrice.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => _costPrice = double.tryParse(val ?? '') ?? _costPrice,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Retail Price (\$)',
                            initialValue: _retailPrice.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onSaved: (val) => _retailPrice = double.tryParse(val ?? '') ?? _retailPrice,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location Layout
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Aisle',
                            initialValue: _aisle,
                            onSaved: (val) => _aisle = val ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Shelf',
                            initialValue: _shelf,
                            onSaved: (val) => _shelf = val ?? '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Capacity Layout
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Shelf Capacity',
                            initialValue: _shelfCapacity.toString(),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _shelfCapacity = int.tryParse(val ?? '') ?? _shelfCapacity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Min Stock Level',
                            initialValue: _minStockLevel.toString(),
                            keyboardType: TextInputType.number,
                            onSaved: (val) => _minStockLevel = int.tryParse(val ?? '') ?? _minStockLevel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Supplier
                    _buildTextField(
                      label: 'Supplier Partner',
                      initialValue: _supplier,
                      onSaved: (val) => _supplier = val ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rationale Bento
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rationale for Adjustments', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Please detail reasoning e.g., competitor pricing alignment, wholesale cost hikes, aisle rearrangement...',
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSaved: (val) {
                        _reason = val ?? '';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit Suggestion', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final newRequest = RequestItem(
                        id: 'REQ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        type: RequestType.productSuggestion,
                        title: 'Product Suggestion - SKU-${_selectedSku.replaceAll('SKU-', '')}',
                        description: 'Proposed update details for $_name',
                        status: RequestStatus.pending,
                        submissionDate: DateTime.now(),
                        timeline: [
                          TimelineEvent(
                            title: 'Suggestion Submitted',
                            description: 'Submitted by ${appState.currentUser.name}',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Awaiting Manager Review',
                            description: 'Routed for inventory coordination check',
                            timestamp: DateTime.now(),
                          ),
                        ],
                        details: {
                          'sku': _selectedSku,
                          'originalName': _name,
                          'suggestedName': _name,
                          'costPrice': _costPrice,
                          'retailPrice': _retailPrice,
                          'aisle': _aisle,
                          'shelf': _shelf,
                          'shelfCapacity': _shelfCapacity,
                          'minStockLevel': _minStockLevel,
                          'supplier': _supplier,
                          'reason': _reason,
                        },
                      );

                      appState.addRequest(newRequest);

                      // If current user is the Manager, automatically approve/resolve it to show manager flow!
                      if (appState.currentUser.role == UserRole.manager) {
                        final updatedProduct = appState.products.firstWhere((p) => p.sku == _selectedSku).copyWith(
                          name: _name,
                          costPrice: _costPrice,
                          retailPrice: _retailPrice,
                          aisle: _aisle,
                          shelf: _shelf,
                          shelfCapacity: _shelfCapacity,
                          minStockLevel: _minStockLevel,
                          supplier: _supplier,
                          history: [
                            '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year} - Updated parameters via manager approval',
                          ],
                        );
                        appState.updateProduct(updatedProduct);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Suggestion submitted. Log ID: ${newRequest.id}'),
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

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Please fill in this field';
            return null;
          },
          onSaved: onSaved,
        ),
      ],
    );
  }
}
