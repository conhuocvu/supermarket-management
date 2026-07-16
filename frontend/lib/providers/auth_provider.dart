import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/supabase_auth_state.dart';
import '../services/api_service.dart';

class AuthNotifier extends StateNotifier<SupabaseAuthState> {
  final SupabaseClient _client;
  StreamSubscription<AuthState>? _subscription;

  AuthNotifier({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(SupabaseAuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final initialSession = _client.auth.currentSession;
      final initialUser = _client.auth.currentUser;

      Profile? profile;
      if (initialUser != null) {
        profile = await _fetchProfileData(initialUser.id);
      }

      state = SupabaseAuthState(
        isInitialized: true,
        user: initialUser,
        session: initialSession,
        profile: profile,
      );
    } catch (e) {
      state = SupabaseAuthState(
        isInitialized: true,
        errorMessage: 'Failed to initialize session: $e',
      );
    }

    // Listen for subsequent auth state changes
    _subscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final user = session?.user ?? _client.auth.currentUser;

      if (user == null) {
        state = SupabaseAuthState(
          isInitialized: true,
          user: null,
          session: null,
          profile: null,
        );
      } else {
        if (state.user?.id != user.id || state.profile == null) {
          final profile = await _fetchProfileData(user.id);
          state = SupabaseAuthState(
            isInitialized: true,
            user: user,
            session: session,
            profile: profile,
          );
        } else {
          state = state.copyWith(user: user, session: session);
        }
      }
    });
  }

  /// Fetches profile data through the Spring Boot backend (Issue #2 fix).
  /// Falls back gracefully if backend is unavailable, retrying up to 3 times.
  Future<Profile?> _fetchProfileData(String userId) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        return await ApiService().fetchProfile(userId);
      } catch (e) {
        debugPrint('Error fetching profile via backend (attempt $attempt): $e');
      }
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _translateAuthError(e.message),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      rethrow;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      state = state.copyWith(isSubmitting: false);
      return response;
    } on AuthException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _translateAuthError(e.message),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _client.auth.signOut();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to sign out: $e',
      );
    }
  }

  Future<void> refreshProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final profile = await _fetchProfileData(user.id);
    // copyWith does not fall back to previous user/session, so pass them explicitly
    state = state.copyWith(
      user: user,
      session: _client.auth.currentSession,
      profile: profile,
    );
  }

  /// Updates the local profile state directly from a ProfileDTO returned by
  /// the backend update endpoint — avoids a redundant network fetch (Issue #5).
  void updateProfileState(Profile updatedProfile) {
    state = state.copyWith(
      user: _client.auth.currentUser,
      session: _client.auth.currentSession,
      profile: updatedProfile,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please check your email and confirm your account first.';
    }
    if (lower.contains('user already exists')) {
      return 'This email is already registered.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network connection issue. Please check your internet.';
    }
    return message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, SupabaseAuthState>((
  ref,
) {
  return AuthNotifier();
});
