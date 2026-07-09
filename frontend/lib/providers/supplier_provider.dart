import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/errors/app_error.dart';
import 'package:frontend/models/supplier.dart';
import 'package:frontend/models/supplier_product.dart';
import 'package:frontend/providers/employee_provider.dart';

final supplierCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');
final supplierSearchQueryProvider = StateProvider<String>((ref) => '');

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final api = ref.watch(apiServiceProvider);
    final search = ref.watch(supplierSearchQueryProvider);
    final category = ref.watch(supplierCategoryFilterProvider);

    final result = await api.getSuppliers(search: search, category: category);
    if (result.isSuccess) {
      return result.data!;
    } else {
      throw Exception(result.error!.userMessage);
    }
  }

  Future<Result<Supplier>> createSupplier({
    required String code,
    required String name,
    required String category,
    required String nextDelivery,
    required String status,
    required String contactType,
    required String contactValue,
    required double onTimeDeliveryRate,
    required double averageRating,
    required String notes,
    required String certification,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.createSupplier(
      code: code,
      name: name,
      category: category,
      nextDelivery: nextDelivery,
      status: status,
      contactType: contactType,
      contactValue: contactValue,
      onTimeDeliveryRate: onTimeDeliveryRate,
      averageRating: averageRating,
      notes: notes,
      certification: certification,
    );

    if (result.isSuccess) {
      ref.invalidateSelf();
    }
    return result;
  }

  Future<Result<Supplier>> updateSupplier(
    int id, {
    required String code,
    required String name,
    required String category,
    required String nextDelivery,
    required String status,
    required String contactType,
    required String contactValue,
    required double onTimeDeliveryRate,
    required double averageRating,
    required String notes,
    required String certification,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.updateSupplier(
      id,
      code: code,
      name: name,
      category: category,
      nextDelivery: nextDelivery,
      status: status,
      contactType: contactType,
      contactValue: contactValue,
      onTimeDeliveryRate: onTimeDeliveryRate,
      averageRating: averageRating,
      notes: notes,
      certification: certification,
    );

    if (result.isSuccess) {
      ref.invalidateSelf();
      ref.invalidate(supplierDetailProvider(id));
    }
    return result;
  }

  Future<Result<Supplier>> updateSupplierStatus(int id, String status) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.updateSupplierStatus(id, status);
    if (result.isSuccess) {
      ref.invalidateSelf();
      ref.invalidate(supplierDetailProvider(id));
    }
    return result;
  }
}

final suppliersProvider =
    AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(() {
  return SuppliersNotifier();
});

final supplierDetailProvider = FutureProvider.family<Supplier, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final result = await api.getSupplier(id);
  if (result.isSuccess) {
    return result.data!;
  } else {
    throw Exception(result.error!.userMessage);
  }
});

// ─── Supplier Products (for Assign Products screen) ───────────────────────────

class SupplierProductsNotifier
    extends StateNotifier<AsyncValue<List<SupplierProduct>>> {
  final Ref ref;
  final int supplierId;

  SupplierProductsNotifier(this.ref, this.supplierId)
      : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    final api = ref.read(apiServiceProvider);
    final result = await api.getSupplierProducts(supplierId);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error!.userMessage, StackTrace.current);
    }
  }

  void toggleProductAssignment(int productId) {
    state.whenData((list) {
      state = AsyncValue.data(list.map((sp) {
        if (sp.productId == productId) {
          return SupplierProduct(
            id: sp.id,
            productId: sp.productId,
            sku: sp.sku,
            name: sp.name,
            category: sp.category,
            basePrice: sp.basePrice,
            importPrice: sp.importPrice,
            unit: sp.unit,
            imageUrl: sp.imageUrl,
            assigned: !sp.assigned,
          );
        }
        return sp;
      }).toList());
    });
  }

  void updateImportPrice(int productId, double price) {
    state.whenData((list) {
      state = AsyncValue.data(list.map((sp) {
        if (sp.productId == productId) {
          return SupplierProduct(
            id: sp.id,
            productId: sp.productId,
            sku: sp.sku,
            name: sp.name,
            category: sp.category,
            basePrice: sp.basePrice,
            importPrice: price,
            unit: sp.unit,
            imageUrl: sp.imageUrl,
            assigned: sp.assigned,
          );
        }
        return sp;
      }).toList());
    });
  }

  Future<Result<List<SupplierProduct>>> confirmAssignments() async {
    final api = ref.read(apiServiceProvider);

    List<Map<String, dynamic>> payload = [];
    state.whenData((list) {
      for (var sp in list) {
        if (sp.assigned) {
          payload.add({
            'productId': sp.productId,
            'importPrice': sp.importPrice,
          });
        }
      }
    });

    final result = await api.assignProducts(supplierId, payload);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
      ref.invalidate(supplierDetailProvider(supplierId));
    }
    return result;
  }
}

final supplierProductsProvider = StateNotifierProvider.family<
    SupplierProductsNotifier, AsyncValue<List<SupplierProduct>>, int>(
  (ref, supplierId) => SupplierProductsNotifier(ref, supplierId),
);
