import 'package:equatable/equatable.dart';

/// A vehicle (bus/van/minibus) as returned by `POST /vehicles` or `GET /vehicles` (FLT-001).
class CreatedVehicle extends Equatable {
  const CreatedVehicle({
    required this.id,
    required this.schoolId,
    required this.registrationNo,
    required this.displayName,
    required this.vehicleType,
    required this.seatingCapacity,
    required this.status,
    this.vendorName,
  });

  final String id;
  final String schoolId;
  final String registrationNo;

  /// What parents see in notifications — "Bus 12", not the plate number (NTF-BOARD-01).
  final String displayName;
  final String vehicleType;
  final int seatingCapacity;
  final String? vendorName;
  final String status;

  @override
  List<Object?> get props => [
        id,
        schoolId,
        registrationNo,
        displayName,
        vehicleType,
        seatingCapacity,
        vendorName,
        status,
      ];
}
