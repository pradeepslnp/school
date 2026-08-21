import 'package:equatable/equatable.dart';

/// What the operator did on the Vehicles screen (A-20).
sealed class VehicleListEvent extends Equatable {
  const VehicleListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, or the operator asked to refresh, for one school's fleet.
final class VehicleListRequested extends VehicleListEvent {
  const VehicleListRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator registered a new vehicle (FLT-001).
final class VehicleCreated extends VehicleListEvent {
  const VehicleCreated({
    required this.schoolId,
    required this.registrationNo,
    required this.displayName,
    required this.vehicleType,
    required this.seatingCapacity,
    this.vendorName,
  });

  final String schoolId;
  final String registrationNo;
  final String displayName;
  final String vehicleType;
  final int seatingCapacity;
  final String? vendorName;

  @override
  List<Object?> get props =>
      [schoolId, registrationNo, displayName, vehicleType, seatingCapacity, vendorName];
}
