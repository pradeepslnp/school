import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/stop_models.dart';

/// A route's stops editor (RTE-001) — the working list plus its loading, saving, and error
/// conditions.
///
/// [stops] is the working list the operator is editing, not necessarily what the server holds:
/// [isDirty] is true once it has been changed and not yet saved. A route needs at least two
/// stops before it can carry students (BR-ROUTE-001), so [canSave] gates the save button on that
/// the same way the server does.
class RouteStopsState extends Equatable {
  const RouteStopsState({
    this.isLoading = false,
    this.isSaving = false,
    this.stops = const [],
    this.isDirty = false,
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSaving;
  final List<RouteStop> stops;

  /// Whether the working list has unsaved changes.
  final bool isDirty;

  final ErrorCode? error;
  final String? errorMessageKey;

  /// BR-ROUTE-001: a route needs at least two stops. The button is disabled below that so the
  /// operator sees the rule before the server refuses it.
  bool get canSave => stops.length >= 2 && isDirty && !isSaving;

  RouteStopsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<RouteStop>? stops,
    bool? isDirty,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return RouteStopsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      stops: stops ?? this.stops,
      isDirty: isDirty ?? this.isDirty,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, isSaving, stops, isDirty, error, errorMessageKey];
}
