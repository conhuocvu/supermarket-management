import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/dashboard_data.dart';

void main() {
  group('DashboardData Serialization Tests', () {
    test('should correctly parse DashboardData from valid JSON', () {
      final json = {
        'totalProducts': 1240,
        'lowStockCount': 12,
        'nearExpiryCount': 8,
        'pendingRequestsCount': 5,
        'capacityUsed': 85.0,
        'updatedAt': '2026-07-07T22:30:00Z',
        'recentActivities': [
          {
            'action': 'Stock-in',
            'item': 'Milk',
            'quantity': '50 Cartons',
            'time': '2026-07-07T10:45:00Z',
          },
          {
            'action': 'Stock-out',
            'item': 'Bread',
            'quantity': '10 Loaves',
            'time': '2026-07-07T09:30:00Z',
          },
        ],
      };

      final data = DashboardData.fromJson(json);

      expect(data.totalProducts, equals(1240));
      expect(data.lowStockCount, equals(12));
      expect(data.nearExpiryCount, equals(8));
      expect(data.pendingRequestsCount, equals(5));
      expect(data.capacityUsed, equals(85.0));
      expect(data.recentActivities.length, equals(2));

      expect(data.recentActivities[0].action, equals('Stock-in'));
      expect(data.recentActivities[0].item, equals('Milk'));
      expect(data.recentActivities[0].quantity, equals('50 Cartons'));

      expect(data.recentActivities[1].action, equals('Stock-out'));
      expect(data.recentActivities[1].item, equals('Bread'));
      expect(data.recentActivities[1].quantity, equals('10 Loaves'));
    });

    test(
      'should fallback to default values when JSON contains null fields',
      () {
        final json = {
          'totalProducts': null,
          'lowStockCount': null,
          'nearExpiryCount': null,
          'pendingRequestsCount': null,
          'capacityUsed': null,
          'updatedAt': null,
          'recentActivities': null,
        };

        final data = DashboardData.fromJson(json);

        expect(data.totalProducts, equals(0));
        expect(data.lowStockCount, equals(0));
        expect(data.nearExpiryCount, equals(0));
        expect(data.pendingRequestsCount, equals(0));
        expect(data.capacityUsed, equals(0.0));
        expect(data.recentActivities, isEmpty);
      },
    );
  });
}
