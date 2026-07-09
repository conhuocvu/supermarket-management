import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/promotion.dart';
import 'package:frontend/core/errors/app_error.dart';
import 'package:frontend/providers/employee_provider.dart';

// Provide search query state for promotions
final promotionSearchQueryProvider = StateProvider<String>((ref) => '');

// Provide category filter state (ALL, Seasonal, BOGO, Flash Sale, Dairy, Bakery, etc.)
final promotionCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');

class PromotionsNotifier extends AsyncNotifier<List<Promotion>> {
  @override
  Future<List<Promotion>> build() async {
    // Wait until the mock JWT token is retrieved
    await ref.watch(mockTokenProvider.future);

    final api = ref.watch(apiServiceProvider);
    final search = ref.watch(promotionSearchQueryProvider);
    final category = ref.watch(promotionCategoryFilterProvider);

    final result = await api.getPromotions(search: search, category: category);
    return result.dataOrThrow;
  }

  Future<Result<Promotion>> createPromotion({
    required String name,
    required String code,
    required String priority,
    required String discountType,
    required double discountValue,
    String? description,
    List<String>? targetCategories,
    List<String>? targetProducts,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? visibility,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.createPromotion(
      name: name,
      code: code,
      priority: priority,
      discountType: discountType,
      discountValue: discountValue,
      description: description,
      targetCategories: targetCategories,
      targetProducts: targetProducts,
      startDate: startDate,
      endDate: endDate,
      imageUrl: imageUrl,
      visibility: visibility,
    );
    if (result.isSuccess) {
      ref.invalidateSelf();
    }
    return result;
  }

  Future<Result<Promotion>> updatePromotion(
    int id, {
    required String name,
    required String code,
    required String priority,
    required String discountType,
    required double discountValue,
    String? description,
    List<String>? targetCategories,
    List<String>? targetProducts,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? visibility,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.updatePromotion(
      id,
      name: name,
      code: code,
      priority: priority,
      discountType: discountType,
      discountValue: discountValue,
      description: description,
      targetCategories: targetCategories,
      targetProducts: targetProducts,
      startDate: startDate,
      endDate: endDate,
      imageUrl: imageUrl,
      visibility: visibility,
    );
    if (result.isSuccess) {
      ref.invalidate(promotionDetailProvider(id));
      ref.invalidateSelf();
    }
    return result;
  }

  Future<Result<void>> deletePromotion(int id) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.deletePromotion(id);
    if (result.isSuccess) {
      ref.invalidate(promotionDetailProvider(id));
      ref.invalidateSelf();
    }
    return result;
  }
}

final promotionsProvider = AsyncNotifierProvider<PromotionsNotifier, List<Promotion>>(() {
  return PromotionsNotifier();
});

// FutureProvider for single promotion details
final promotionDetailProvider = FutureProvider.family<Promotion, int>((ref, id) async {
  await ref.watch(mockTokenProvider.future);
  final api = ref.watch(apiServiceProvider);
  final result = await api.getPromotion(id);
  return result.dataOrThrow;
});
