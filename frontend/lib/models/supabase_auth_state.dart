import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';

class SupabaseAuthState {
  final bool isInitialized;
  final bool isSubmitting;
  final User? user;
  final Session? session;
  final Profile? profile;
  final String? errorMessage;

  SupabaseAuthState({
    this.isInitialized = false,
    this.isSubmitting = false,
    this.user,
    this.session,
    this.profile,
    this.errorMessage,
  });

  SupabaseAuthState copyWith({
    bool? isInitialized,
    bool? isSubmitting,
    User? user,
    Session? session,
    Profile? profile,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return SupabaseAuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      user: user,
      session: session,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
