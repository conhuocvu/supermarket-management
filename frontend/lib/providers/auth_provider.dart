import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/supabase_auth_state.dart';

class AuthNotifier extends StateNotifier<SupabaseAuthState> {
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _subscription;

  AuthNotifier() : super(SupabaseAuthState()) {
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

  Future<Profile?> _fetchProfileData(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        return Profile.fromJson(data);
      }
    } catch (e) {
      // Don't crash auth state, just log and return null
      debugPrint('Error fetching profile: $e');
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
