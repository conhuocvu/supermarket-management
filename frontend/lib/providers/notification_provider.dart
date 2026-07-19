import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import 'dashboard_provider.dart' show apiServiceProvider;

final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<NotificationItem>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationNotifier(apiService);
});

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final ApiService _apiService;

  NotificationNotifier(this._apiService) : super(const AsyncValue.loading());

  int get unreadCount =>
      state.valueOrNull?.where((n) => !n.isRead).length ?? 0;

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.fetchNotifications(userId);
      state = AsyncValue.data(
        data.map<NotificationItem>((e) => NotificationItem.fromJson(e)).toList(),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Marks one notification read. Updates local state optimistically and
  /// reverts by reloading if the API call fails.
  Future<void> markRead(int notificationNumber, String userId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data([
      for (final n in current)
        n.notificationNumber == notificationNumber
            ? n.copyWith(isRead: true)
            : n,
    ]);
    try {
      await _apiService.markNotificationRead(notificationNumber, userId);
    } catch (_) {
      await load(userId);
      rethrow;
    }
  }

  /// Marks everything read. Optimistic, reverts by reloading on failure.
  Future<void> markAllRead(String userId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(
      [for (final n in current) n.copyWith(isRead: true)],
    );
    try {
      await _apiService.markAllNotificationsRead(userId);
    } catch (_) {
      await load(userId);
      rethrow;
    }
  }

  /// Re-fetches while keeping current data visible; rethrows on failure so
  /// the caller can show a snackbar (same pattern as attendance/dashboard).
  Future<void> refresh(String userId) async {
    try {
      final data = await _apiService.fetchNotifications(userId);
      state = AsyncValue.data(
        data.map<NotificationItem>((e) => NotificationItem.fromJson(e)).toList(),
      );
    } catch (e, stackTrace) {
      if (state.hasValue) {
        rethrow;
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}
