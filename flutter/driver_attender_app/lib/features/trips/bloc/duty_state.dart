import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/trip_models.dart';

/// What the Today screen is showing (TRP-004).
///
/// [loadedAt] is null until the first successful load. That is the difference between "you have
/// no runs today" and "we have not managed to ask yet", and a driver standing at a bus must not
/// be shown the first when the second is true.
class DutyState extends Equatable {
  const DutyState({
    this.trips = const [],
    this.isLoading = false,
    this.submittingTripId,
    this.error,
    this.errorMessageKey,
    this.loadedAt,
  });

  final List<CrewTrip> trips;
  final bool isLoading;

  /// The run whose start or end is in flight, so only that row shows a spinner.
  final String? submittingTripId;

  final ErrorCode? error;
  final String? errorMessageKey;
  final DateTime? loadedAt;

  bool get hasLoaded => loadedAt != null;
  bool get isEmpty => hasLoaded && trips.isEmpty;

  DutyState copyWith({
    List<CrewTrip>? trips,
    bool? isLoading,
    String? submittingTripId,
    bool clearSubmitting = false,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    DateTime? loadedAt,
  }) {
    return DutyState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      submittingTripId:
          clearSubmitting ? null : (submittingTripId ?? this.submittingTripId),
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  @override
  List<Object?> get props =>
      [trips, isLoading, submittingTripId, error, errorMessageKey, loadedAt];
}
