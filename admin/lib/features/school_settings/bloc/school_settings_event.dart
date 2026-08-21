import 'package:equatable/equatable.dart';

/// What the operator did on the School screen (A-41).
sealed class SchoolSettingsEvent extends Equatable {
  const SchoolSettingsEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen was shown, for the signed-in operator's own school.
final class SchoolSettingsRequested extends SchoolSettingsEvent {
  const SchoolSettingsRequested({required this.schoolId});

  final String schoolId;

  @override
  List<Object?> get props => [schoolId];
}

/// The operator saved changes to the school's details from the edit form (TEN-002).
final class SchoolSettingsSaved extends SchoolSettingsEvent {
  const SchoolSettingsSaved({
    required this.schoolId,
    required this.organizationId,
    required this.name,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusM,
  });

  final String schoolId;
  final String organizationId;
  final String name;
  final String timezone;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;

  @override
  List<Object?> get props =>
      [schoolId, organizationId, name, timezone, latitude, longitude, geofenceRadiusM];
}
