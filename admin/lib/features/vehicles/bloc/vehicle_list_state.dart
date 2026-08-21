import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/vehicle_models.dart';

/// The Vehicles screen (A-20), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `StaffListState` — every field the
/// screen renders is here.
class VehicleListState extends Equatable {
  const VehicleListState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.vehicles = const [],
    this.error,
    this.errorMessageKey,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<CreatedVehicle> vehicles;

  /// The last failure, or null. Cleared whenever a new request starts.
  final ErrorCode? error;
  final String? errorMessageKey;

  VehicleListState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CreatedVehicle>? vehicles,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
  }) {
    return VehicleListState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      vehicles: vehicles ?? this.vehicles,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
    );
  }

  @override
  List<Object?> get props => [isLoading, isSubmitting, vehicles, error, errorMessageKey];
}
