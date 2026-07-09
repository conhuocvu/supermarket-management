import 'package:flutter/material.dart';
import 'product.dart';
import 'request.dart';
import 'notification_item.dart';

enum UserRole { manager, associate, cashier, stockController }

class AppUser {
  final String name;
  final String title;
  final UserRole role;
  final String imageUrl;
  final String email;
  final String phone;
  final String workHoursThisWeek;
  final String nextShift;

  AppUser({
    required this.name,
    required this.title,
    required this.role,
    required this.imageUrl,
    required this.email,
    required this.phone,
    required this.workHoursThisWeek,
    required this.nextShift,
  });
}

class AppState extends ChangeNotifier {
  late AppUser currentUser;
  late List<Product> products;
  late List<RequestItem> requests;
  late List<NotificationItem> notifications;
  bool isDarkMode = false;
  int currentTabIndex = 0;
  bool isCheckedIn = false;
  String checkInTime = '--:--';
  String checkOutTime = '--:--';

  void toggleCheckIn() {
    isCheckedIn = !isCheckedIn;
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    if (isCheckedIn) {
      checkInTime = timeStr;
      checkOutTime = '--:--';
    } else {
      checkOutTime = timeStr;
    }
    notifyListeners();
  }

  final AppUser managerUser = AppUser(
    name: 'Sarah Jenkins',
    title: 'Manager',
    role: UserRole.manager,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDd5Bresu18pLvh1YpI6y445O4odoxNVmbTfdhYK6N30wXG2OWJOjr_uMEQZ9FIy8KO1CPsiDAWlW4j1Vzx8KQbFzQvWNc1t3emnJ0yzRRR4EoPGSnKx-BVvS4R23ewcJCpnDA3r_GNl_TXepFa-SP4W0hoc3yJPJInMdcf6cVIJ5xX7vZTiYWn5bDlEf6yQVs50w1lfPnyZcOekSCb4M7SqSZcl7t6SKNadaNG-lR1EHgP_lqtPnPhkf9UDLehYgwabv9rsLwURCzr',
    email: 'sarah.jenkins@greenmart.com',
    phone: '+1 (555) 392-8812',
    workHoursThisWeek: '38.5 hrs',
    nextShift: 'Tomorrow, 08:00 AM - 04:30 PM',
  );

  final AppUser associateUser = AppUser(
    name: 'Alex Rivera',
    title: 'Sales Associate',
    role: UserRole.associate,
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAU9wNHHpKdhrvsfejE6o8HowkkHQvPDuWO-dP_m_Z5Nidc1y4uytCW-seLllMd8R-TngYspVc2p-79_s2DaJ4vQWL107-qYDOI33GO8EySq_ARLRSWUUnqX5fo6Rky0_XW7QtJCT22J6nLKOsu8YVw9v6UJ-v6PGSAk1W8ooY8OhWdIk2O-ACciFGVRWi4Jkpf2HmLlUA4WF0DUj-kNSUCHz5idbsObhqS6RWF6Tf8dCaOT1YKHJ191fYG2AUtMJ1hqAKWWji4qr-w',
    email: 'alex.rivera@greenmart.com',
    phone: '+1 (555) 782-9011',
    workHoursThisWeek: '32.0 hrs',
    nextShift: 'Today, 10:00 AM - 06:30 PM',
  );

  final AppUser cashierUser = AppUser(
    name: 'Emma Chen',
    title: 'Cashier',
    role: UserRole.cashier,
    imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    email: 'emma.chen@greenmart.com',
    phone: '+1 (555) 438-2910',
    workHoursThisWeek: '28.0 hrs',
    nextShift: 'Today, 12:00 PM - 08:30 PM',
  );

  final AppUser stockControllerUser = AppUser(
    name: 'Marcus Vance',
    title: 'Stock Controller',
    role: UserRole.stockController,
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    email: 'marcus.vance@greenmart.com',
    phone: '+1 (555) 902-1134',
    workHoursThisWeek: '36.0 hrs',
    nextShift: 'Tomorrow, 06:00 AM - 02:30 PM',
  );

  AppState() {
    // Start as Manager Sarah Jenkins (since she has more screens in the desktop mockups)
    currentUser = managerUser;
    _initializeMockData();
  }

  void switchUser() {
    if (currentUser.role == UserRole.manager) {
      currentUser = associateUser;
    } else if (currentUser.role == UserRole.associate) {
      currentUser = cashierUser;
    } else if (currentUser.role == UserRole.cashier) {
      currentUser = stockControllerUser;
    } else {
      currentUser = managerUser;
    }
    notifyListeners();
  }

  void switchUserRole(UserRole role) {
    switch (role) {
      case UserRole.manager:
        currentUser = managerUser;
        break;
      case UserRole.associate:
        currentUser = associateUser;
        break;
      case UserRole.cashier:
        currentUser = cashierUser;
        break;
      case UserRole.stockController:
        currentUser = stockControllerUser;
        break;
    }
    notifyListeners();
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  void setTabIndex(int index) {
    currentTabIndex = index;
    notifyListeners();
  }

  void _initializeMockData() {
    products = [
      Product(
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
        history: ['Jul 07, 2026 - Received 20 units', 'Jul 08, 2026 - Restocked shelf (10 units)'],
      ),
      Product(
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
        history: ['Jul 06, 2026 - Received 100 units', 'Jul 08, 2026 - Culled 5 damaged items'],
      ),
      Product(
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
        history: ['Jul 05, 2026 - Received 120 units', 'Jul 08, 2026 - Sold out (0 units left)'],
      ),
      Product(
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
        history: ['Jul 07, 2026 - Received 15 units', 'Jul 08, 2026 - Low stock warning triggered'],
      ),
      Product(
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
    ];

    requests = [
      RequestItem(
        id: 'REQ-2026-001',
        type: RequestType.leave,
        title: 'Annual Vacation Leave',
        description: '3 days of paid vacation leave',
        status: RequestStatus.approved,
        submissionDate: DateTime.now().subtract(const Duration(days: 5)),
        timeline: [
          TimelineEvent(title: 'Request Submitted', description: 'Submitted by Sarah Jenkins', timestamp: DateTime.now().subtract(const Duration(days: 5))),
          TimelineEvent(title: 'Manager Assigned', description: 'Routed to HR Operations', timestamp: DateTime.now().subtract(const Duration(days: 5))),
          TimelineEvent(title: 'Request Approved', description: 'Approved by HR Director Mark Benson', timestamp: DateTime.now().subtract(const Duration(days: 4))),
        ],
        details: {
          'leaveType': 'Vacation',
          'startDate': '2026-07-20',
          'endDate': '2026-07-22',
          'reason': 'Family trip to Oregon.',
          'approvedBy': 'Mark Benson (HR)',
        },
      ),
      RequestItem(
        id: 'REQ-2026-002',
        type: RequestType.shiftSwap,
        title: 'Tuesday Shift Swap Request',
        description: 'Swap shift with Marcus Vance',
        status: RequestStatus.pending,
        submissionDate: DateTime.now().subtract(const Duration(days: 2)),
        timeline: [
          TimelineEvent(title: 'Swap Proposed', description: 'Proposed to Marcus Vance for July 14th', timestamp: DateTime.now().subtract(const Duration(days: 2))),
          TimelineEvent(title: 'Colleague Accepted', description: 'Marcus Vance accepted the swap', timestamp: DateTime.now().subtract(const Duration(days: 1))),
          TimelineEvent(title: 'Awaiting Manager Review', description: 'Pending approval by Sarah Jenkins', timestamp: DateTime.now().subtract(const Duration(hours: 12))),
        ],
        details: {
          'currentShiftDate': '2026-07-14',
          'currentShiftTime': '10:00 AM - 06:30 PM',
          'targetShiftDate': '2026-07-14',
          'targetShiftTime': '06:00 AM - 02:30 PM',
          'colleague': 'Marcus Vance',
          'reason': 'Personal dentist appointment.',
        },
      ),
      RequestItem(
        id: 'REQ-2026-003',
        type: RequestType.productSuggestion,
        title: 'Avocado Hass Retail Price Adjustment',
        description: r'Suggest price increase to $2.29',
        status: RequestStatus.pending,
        submissionDate: DateTime.now().subtract(const Duration(hours: 18)),
        timeline: [
          TimelineEvent(title: 'Suggestion Submitted', description: 'Submitted by Sarah Jenkins', timestamp: DateTime.now().subtract(const Duration(hours: 18))),
          TimelineEvent(title: 'Under Review', description: 'Assigned to Pricing Committee', timestamp: DateTime.now().subtract(const Duration(hours: 12))),
        ],
        details: {
          'sku': 'SKU-8821',
          'productName': 'Avocado Hass (Premium)',
          'suggestedPrice': 2.29,
          'reason': 'Supplier wholesale price increased by 15%.',
        },
      ),
      RequestItem(
        id: 'REQ-2026-004',
        type: RequestType.inventoryIssue,
        title: 'Spoiled Organic Whole Milk',
        description: 'Reported 5 damaged/spoiled units',
        status: RequestStatus.resolved,
        submissionDate: DateTime.now().subtract(const Duration(days: 1)),
        timeline: [
          TimelineEvent(title: 'Issue Reported', description: 'Reported by Alex Rivera', timestamp: DateTime.now().subtract(const Duration(days: 1))),
          TimelineEvent(title: 'Disposal Approved', description: 'Floor Manager Sarah Jenkins approved disposal', timestamp: DateTime.now().subtract(const Duration(hours: 22))),
          TimelineEvent(title: 'Resolved', description: 'Inventory counts updated accordingly', timestamp: DateTime.now().subtract(const Duration(hours: 20))),
        ],
        details: {
          'sku': 'SKU-4820',
          'productName': 'Organic Whole Milk',
          'issueType': 'Expired / Spoiled',
          'quantity': 5,
          'aisle': 'Aisle 4',
          'shelf': 'Shelf B-2',
          'description': 'Refrigerator temp fluctuations caused minor souring.',
        },
      ),
    ];

    notifications = [
      NotificationItem(
        id: 'NOT-001',
        title: 'Schedule Adjusted',
        description: 'Your shift next Tuesday (Jul 14) was swapped with Marcus Vance.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.schedule,
      ),
      NotificationItem(
        id: 'NOT-002',
        title: 'Critical Stock Alert',
        description: 'SKU-1049 (Fresh Bananas) is completely out of stock.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.alert,
      ),
      NotificationItem(
        id: 'NOT-003',
        title: 'Task Assigned',
        description: 'Complete shelf cleanup in Aisle 1 (Produce) by end of day.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        type: NotificationType.info,
      ),
    ];
  }

  void addRequest(RequestItem request) {
    requests.insert(0, request);
    notifyListeners();
  }

  void addNotification(NotificationItem notification) {
    notifications.insert(0, notification);
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void updateProductStock(String sku, int newCount) {
    final index = products.indexWhere((p) => p.sku == sku);
    if (index != -1) {
      final updatedProduct = products[index].copyWith(
        stockCount: newCount,
        history: [
          '${_getFormattedDate(DateTime.now())} - Count adjusted to $newCount',
          ...products[index].history,
        ],
      );
      products[index] = updatedProduct;

      // Automatically trigger alert if low stock
      if (newCount <= updatedProduct.minStockLevel) {
        addNotification(NotificationItem(
          id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
          title: newCount == 0 ? 'Out of Stock Alert' : 'Low Stock Alert',
          description: 'SKU-${updatedProduct.sku} (${updatedProduct.name}) has $newCount units left.',
          timestamp: DateTime.now(),
          type: NotificationType.alert,
        ));
      }
      notifyListeners();
    }
  }

  void updateProduct(Product updatedProduct) {
    final index = products.indexWhere((p) => p.sku == updatedProduct.sku);
    if (index != -1) {
      products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void updateRequest(RequestItem updatedRequest) {
    final index = requests.indexWhere((r) => r.id == updatedRequest.id);
    if (index != -1) {
      requests[index] = updatedRequest;
      notifyListeners();
    }
  }

  String _getFormattedDate(DateTime dt) {
    // Simple mock formatting
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }
}
