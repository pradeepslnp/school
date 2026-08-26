import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/platform_health_models.dart';

/// The whole Platform health screen (A-62), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `OrganizationListState` — every
/// field the screen renders is here.
class PlatformHealthState extends Equatable {
  const PlatformHealthState({
    this.isLoading = false,
    this.health,
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;

  /// Null before the first successful read, or after a refresh fails — the screen falls back
  /// to [error] in that case rather than showing a stale reading with no indication it might
  /// be wrong.
  final PlatformHealth? health;

  final ErrorCode? error;
  final String? errorMessageKey;

  PlatformHealthState copyWith({
    bool? isLoading,
    PlatformHealth? health,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return PlatformHealthState(
      isLoading: isLoading ?? this.isLoading,
      health: health ?? this.health,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, health, error, errorMessageKey];
}
