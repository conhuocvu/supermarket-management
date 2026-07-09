import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';
import 'product_detail_screen.dart';
import 'problem_product_details_screen.dart';

class ProblemProductsScreen extends StatefulWidget {
  const ProblemProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProblemProductsScreen> createState() => _ProblemProductsScreenState();
}

class _ProblemProductsScreenState extends State<ProblemProductsScreen> {
  String selectedFilter = 'All';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    // Get products with issues (Low stock / Out of stock)
    final troubledProducts = appState.products.where((p) {
      final isLow = p.stockStatus == 'Low Stock';
      final isOut = p.stockStatus == 'Out of Stock';
      final matchesSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase()) || p.sku.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesFilter = false;
      if (selectedFilter == 'All') {
        matchesFilter = isLow || isOut;
      } else if (selectedFilter == 'Low Stock') {
        matchesFilter = isLow;
      } else if (selectedFilter == 'Out of Stock') {
        matchesFilter = isOut;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Get active inventory issues reported (spoilage reports)
    final reportedSpoilages = appState.requests.where((r) {
      final isSpoilage = r.type == RequestType.inventoryIssue;
      final matchesSearch = r.title.toLowerCase().contains(searchQuery.toLowerCase()) || r.id.toLowerCase().contains(searchQuery.toLowerCase());
      
      bool matchesFilter = false;
      if (selectedFilter == 'All' || selectedFilter == 'Reported Spoilage') {
        matchesFilter = isSpoilage;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Problem Products Alert Center',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by SKU or name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Low Stock', 'Out of Stock', 'Reported Spoilage'].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        }
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Spoilage section
                  if (reportedSpoilages.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Reported Spoilage / Expired Issues',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                      ),
                    ),
                    ...reportedSpoilages.map((req) {
                      return BentoCard(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProblemProductDetailsScreen(request: req),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.report_problem, color: theme.colorScheme.error),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.id,
                                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    req.title,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Quantity: ${req.details["quantity"] ?? 0} units (${req.details["issueType"] ?? ""})',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // Troubled products section
                  if (troubledProducts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Stock Level Warnings',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ),
                    ...troubledProducts.map((p) {
                      final isOut = p.stockCount == 0;
                      return BentoCard(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(sku: p.sku),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isOut ? theme.colorScheme.error : theme.colorScheme.secondary).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOut ? Icons.block : Icons.warning_amber_rounded,
                                color: isOut ? theme.colorScheme.error : theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.sku,
                                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    p.name,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Remaining Stock: ${p.stockCount} / Min Stock: ${p.minStockLevel}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isOut ? theme.colorScheme.error : theme.colorScheme.secondary).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOut ? 'Out of Stock' : 'Low Stock',
                                style: TextStyle(
                                  color: isOut ? theme.colorScheme.error : theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  if (reportedSpoilages.isEmpty && troubledProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              'All quiet! No problem products detected.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
