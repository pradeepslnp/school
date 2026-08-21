import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/route_models.dart';

/// The Routes screen (A-30), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `VehicleListState` — every field the
/// screen renders is here.
class RouteListState extends Equatable {
  const RouteListState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.routes = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<CreatedRoute> routes;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  RouteListState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CreatedRoute>? routes,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return RouteListState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      routes: routes ?? this.routes,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, routes, error, errorMessageKey];
}
