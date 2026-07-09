import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class InventoryIssueForm extends StatefulWidget {
  final String? prefilledSku;

  const InventoryIssueForm({Key? key, this.prefilledSku}) : super(key: key);

  @override
  State<InventoryIssueForm> createState() => _InventoryIssueFormState();
}

class _InventoryIssueFormState extends State<InventoryIssueForm> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedSku;
  String _issueType = 'Damaged';
  int _quantity = 1;
  late String _aisle;
  late String _shelf;
  String _description = '';
  bool _hasPhoto = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Set default values based on prefilledSku or first product
    _selectedSku = widget.prefilledSku ?? appState.products.first.sku;
    _updateLocationFields(appState);
  }

  void _updateLocationFields(AppState appState) {
    final product = appState.products.firstWhere((p) => p.sku == _selectedSku);
    _aisle = product.aisle;
    _shelf = product.shelf;
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
          'Report Inventory Issue',
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
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SKU Dropdown
                    Text('Select Product (SKU)', style: theme.textTheme.labelLarge),
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
                            _updateLocationFields(appState);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Issue Type
                    Text('Issue Type', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _issueType,
                      decoration: InputDecoration(
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: ['Damaged', 'Expired', 'Missing', 'Incorrect Price'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _issueType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity Input
                    Text('Quantity Impacted', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter quantity',
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter quantity';
                        final num = int.tryParse(val);
                        if (num == null || num <= 0) return 'Please enter a valid positive number';
                        return null;
                      },
                      onSaved: (val) {
                        if (val != null) {
                          _quantity = int.parse(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location Bento
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Layout Location', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aisle', style: theme.textTheme.bodySmall),
                              Text(
                                _aisle,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shelf', style: theme.textTheme.bodySmall),
                              Text(
                                _shelf,
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description and Image Upload
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Description / Details', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Provide details on shelf coordinates, expiry dates, or damage levels...',
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSaved: (val) {
                        _description = val ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Photo upload mockup
                    Text('Photo Attachment', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _hasPhoto = !_hasPhoto;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasPhoto
                              ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasPhoto ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
                              color: _hasPhoto ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasPhoto ? 'Photo Attached (issue_photo.jpg)' : 'Take Photo or Upload Image',
                              style: TextStyle(
                                color: _hasPhoto ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                fontWeight: _hasPhoto ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
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
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit Report', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final product = appState.products.firstWhere((p) => p.sku == _selectedSku);

                      // Create and submit request
                      final newRequest = RequestItem(
                        id: 'REQ-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        type: RequestType.inventoryIssue,
                        title: 'Inventory Issue - $_issueType',
                        description: 'Reported $_quantity damaged/spoiled/expired item(s) for ${product.name}',
                        status: RequestStatus.pending,
                        submissionDate: DateTime.now(),
                        timeline: [
                          TimelineEvent(
                            title: 'Report Submitted',
                            description: 'Submitted by ${appState.currentUser.name}',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Under Review',
                            description: 'Awaiting floor manager review & physical checkout',
                            timestamp: DateTime.now(),
                          ),
                        ],
                        details: {
                          'sku': _selectedSku,
                          'productName': product.name,
                          'issueType': _issueType,
                          'quantity': _quantity,
                          'aisle': _aisle,
                          'shelf': _shelf,
                          'description': _description,
                          'hasPhoto': _hasPhoto,
                        },
                      );

                      appState.addRequest(newRequest);

                      // Also deduct stock dynamically if it's "Expired" or "Damaged"
                      if (_issueType == 'Expired' || _issueType == 'Damaged' || _issueType == 'Missing') {
                        final finalStock = (product.stockCount - _quantity).clamp(0, 9999);
                        appState.updateProductStock(_selectedSku, finalStock);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Issue submitted. Log ID: ${newRequest.id}'),
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
}
