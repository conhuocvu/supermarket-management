import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sales_models.dart';

class SalesWorkspaceState {
  final List<SalesProduct> products;
  final List<SalesRequestItem> requests;
  final List<SalesNotification> notifications;
  final bool isCheckedIn;
  final String checkInTime;
  final String checkOutTime;

  const SalesWorkspaceState({
    required this.products,
    required this.requests,
    required this.notifications,
    this.isCheckedIn = false,
    this.checkInTime = '--:--',
    this.checkOutTime = '--:--',
  });

  SalesWorkspaceState copyWith({
    List<SalesProduct>? products,
    List<SalesRequestItem>? requests,
    List<SalesNotification>? notifications,
    bool? isCheckedIn,
    String? checkInTime,
    String? checkOutTime,
  }) {
    return SalesWorkspaceState(
      products: products ?? this.products,
      requests: requests ?? this.requests,
      notifications: notifications ?? this.notifications,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}

class SalesWorkspaceNotifier extends StateNotifier<SalesWorkspaceState> {
  SalesWorkspaceNotifier() : super(_initialState());

  static SalesWorkspaceState _initialState() {
    final now = DateTime.now();
    return SalesWorkspaceState(
      products: const [
        SalesProduct(
          sku: 'SKU-4820',
          name: 'Organic Whole Milk',
          category: 'Dairy',
          costPrice: 2.10,
          retailPrice: 3.49,
          stockCount: 14,
          minStockLevel: 10,
          shelfCapacity: 30,
          aisle: 'Aisle 4',
          shelf: 'Shelf B-2',
          supplier: 'Valley Farms Dairy',
          barcode: '012345678901',
          history: [
            'Jul 07, 2026 - Received 20 units',
            'Jul 08, 2026 - Restocked shelf (10 units)',
          ],
        ),
        SalesProduct(
          sku: 'SKU-8821',
          name: 'Avocado Hass (Premium)',
          category: 'Produce',
          costPrice: 1.05,
          retailPrice: 1.99,
          stockCount: 45,
          minStockLevel: 15,
          shelfCapacity: 80,
          aisle: 'Aisle 1',
          shelf: 'Shelf A-4',
          supplier: 'Global Produce Co.',
          barcode: '088219934102',
          history: [
            'Jul 06, 2026 - Received 100 units',
            'Jul 08, 2026 - Culled 5 damaged items',
          ],
        ),
        SalesProduct(
          sku: 'SKU-1049',
          name: 'Fresh Bananas (Bunch)',
          category: 'Produce',
          costPrice: 0.40,
          retailPrice: 0.89,
          stockCount: 0,
          minStockLevel: 25,
          shelfCapacity: 120,
          aisle: 'Aisle 1',
          shelf: 'Shelf C-1',
          supplier: 'Del Monte Fresh',
          barcode: '048201290384',
          history: [
            'Jul 05, 2026 - Received 120 units',
            'Jul 08, 2026 - Sold out (0 units left)',
          ],
        ),
        SalesProduct(
          sku: 'SKU-3012',
          name: 'Whole Wheat Sourdough Bread',
          category: 'Bakery',
          costPrice: 1.50,
          retailPrice: 2.99,
          stockCount: 8,
          minStockLevel: 8,
          shelfCapacity: 20,
          aisle: 'Aisle 2',
          shelf: 'Shelf D-3',
          supplier: 'Artisanal Bakery & Co.',
          barcode: '030121190471',
          history: [
            'Jul 07, 2026 - Received 15 units',
            'Jul 08, 2026 - Low stock warning triggered',
          ],
        ),
        SalesProduct(
          sku: 'SKU-5091',
          name: 'Sharp Cheddar Cheese 250g',
          category: 'Dairy',
          costPrice: 3.20,
          retailPrice: 4.99,
          stockCount: 25,
          minStockLevel: 10,
          shelfCapacity: 40,
          aisle: 'Aisle 4',
          shelf: 'Shelf A-1',
          supplier: 'Wisconsin Cheese Dist.',
          barcode: '050912239485',
          history: ['Jul 04, 2026 - Received 50 units'],
        ),
      ],
      requests: [
        SalesRequestItem(
          id: 'REQ-2026-003',
          type: SalesRequestType.productSuggestion,
          title: 'Avocado Hass Retail Price Adjustment',
          description: r'Suggest price increase to $2.29',
          status: SalesRequestStatus.pending,
          submissionDate: now.subtract(const Duration(hours: 18)),
          timeline: [
            SalesTimelineEvent(
              title: 'Suggestion Submitted',
              description: 'Submitted by Sales Associate',
              timestamp: now.subtract(const Duration(hours: 18)),
            ),
            SalesTimelineEvent(
              title: 'Under Review',
              description: 'Assigned to Pricing Committee',
              timestamp: now.subtract(const Duration(hours: 12)),
            ),
          ],
          details: const {
            'sku': 'SKU-8821',
            'productName': 'Avocado Hass (Premium)',
            'suggestedPrice': 2.29,
            'reason': 'Supplier wholesale price increased by 15%.',
          },
        ),
        SalesRequestItem(
          id: 'REQ-2026-004',
          type: SalesRequestType.inventoryIssue,
          title: 'Spoiled Organic Whole Milk',
          description: 'Reported 5 damaged/spoiled units',
          status: SalesRequestStatus.resolved,
          submissionDate: now.subtract(const Duration(days: 1)),
          timeline: [
            SalesTimelineEvent(
              title: 'Issue Reported',
              description: 'Reported by Sales Associate',
              timestamp: now.subtract(const Duration(days: 1)),
            ),
            SalesTimelineEvent(
              title: 'Disposal Approved',
              description: 'Floor Manager approved disposal',
              timestamp: now.subtract(const Duration(hours: 22)),
            ),
            SalesTimelineEvent(
              title: 'Resolved',
              description: 'Inventory counts updated accordingly',
              timestamp: now.subtract(const Duration(hours: 20)),
            ),
          ],
          details: const {
            'sku': 'SKU-4820',
            'productName': 'Organic Whole Milk',
            'issueType': 'Expired / Spoiled',
            'quantity': 5,
            'aisle': 'Aisle 4',
            'shelf': 'Shelf B-2',
            'description':
                'Refrigerator temp fluctuations caused minor souring.',
          },
        ),
      ],
      notifications: [
        SalesNotification(
          id: 'NOT-001',
          title: 'Schedule Adjusted',
          description:
              'Your shift next Tuesday (Jul 14) was swapped with a colleague.',
          timestamp: now.subtract(const Duration(hours: 2)),
          type: SalesNotificationType.schedule,
        ),
        SalesNotification(
          id: 'NOT-002',
          title: 'Critical Stock Alert',
          description: 'SKU-1049 (Fresh Bananas) is completely out of stock.',
          timestamp: now.subtract(const Duration(hours: 5)),
          type: SalesNotificationType.alert,
        ),
        SalesNotification(
          id: 'NOT-003',
          title: 'Task Assigned',
          description:
              'Complete shelf cleanup in Aisle 1 (Produce) by end of day.',
          timestamp: now.subtract(const Duration(hours: 8)),
          type: SalesNotificationType.info,
        ),
      ],
    );
  }

  void toggleCheckIn() {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    if (!state.isCheckedIn) {
      state = state.copyWith(
        isCheckedIn: true,
        checkInTime: timeStr,
        checkOutTime: '--:--',
      );
    } else {
      state = state.copyWith(isCheckedIn: false, checkOutTime: timeStr);
    }
  }

  void addRequest(SalesRequestItem request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void updateRequest(SalesRequestItem updated) {
    final requests = state.requests
        .map((r) => r.id == updated.id ? updated : r)
        .toList();
    state = state.copyWith(requests: requests);
  }

  void addNotification(SalesNotification notification) {
    state = state.copyWith(notifications: [notification, ...state.notifications]);
  }

  void markAllNotificationsAsRead() {
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  void updateProduct(SalesProduct updated) {
    final products =
        state.products.map((p) => p.sku == updated.sku ? updated : p).toList();
    state = state.copyWith(products: products);
  }

  void updateProductStock(String sku, int newCount) {
    final index = state.products.indexWhere((p) => p.sku == sku);
    if (index == -1) return;

    final product = state.products[index];
    final updated = product.copyWith(
      stockCount: newCount,
      history: [
        '${_formatDate(DateTime.now())} - Count adjusted to $newCount',
        ...product.history,
      ],
    );
    final products = [...state.products];
    products[index] = updated;
    state = state.copyWith(products: products);

    if (newCount <= updated.minStockLevel) {
      addNotification(
        SalesNotification(
          id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
          title: newCount == 0 ? 'Out of Stock Alert' : 'Low Stock Alert',
          description:
              '${updated.sku} (${updated.name}) has $newCount units left.',
          timestamp: DateTime.now(),
          type: SalesNotificationType.alert,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }
}

final salesWorkspaceProvider =
    StateNotifierProvider<SalesWorkspaceNotifier, SalesWorkspaceState>((ref) {
  return SalesWorkspaceNotifier();
});
