import 'package:equatable/equatable.dart';

/// An organization as returned by `POST /organizations` or `PATCH /organizations/{id}`
/// (TEN-001).
///
/// Carries every field the details/edit view needs to pre-fill its form — not just the three
/// the create step originally needed — so viewing what was just created never requires a
/// second round trip.
class CreatedOrganization extends Equatable {
  const CreatedOrganization({
    required this.id,
    required this.code,
    required this.name,
    required this.regionProfileCode,
    this.contactEmail,
    this.contactPhone,
  });

  final String id;
  final String code;
  final String name;
  final String regionProfileCode;
  final String? contactEmail;
  final String? contactPhone;

  @override
  List<Object?> get props =>
      [id, code, name, regionProfileCode, contactEmail, contactPhone];
}

/// A school as returned by `GET /schools/{id}`, `POST /schools`, or `PATCH /schools/{id}`
/// (TEN-002), under a [CreatedOrganization].
class CreatedSchool extends Equatable {
  const CreatedSchool({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.name,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusM,
  });

  final String id;

  /// Carried on the school itself, not just its parent [CreatedOrganization] — `PATCH
  /// /schools/{id}` requires it in the body (`UpdateSchoolRequest`), and School Settings
  /// (A-41) reaches a school directly by id without ever holding its organization in
  /// memory, so this is the only place that id is available to send back.
  final String organizationId;
  final String code;
  final String name;
  final String timezone;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;

  @override
  List<Object?> get props =>
      [id, organizationId, code, name, timezone, latitude, longitude, geofenceRadiusM];
}
