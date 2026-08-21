import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/absence_data_provider.dart';
import 'models/absence.dart';

/// Turns absence transport into domain meaning.
///
/// The BLoC depends on this, never on [AbsenceDataProvider] (ENGINEERING_PRINCIPLES.md §4).
class AbsenceRepository {
  AbsenceRepository({required this.dataProvider});

  final AbsenceDataProvider dataProvider;

  Future<Result<Absence>> declareAbsence({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required AbsenceDirection direction,
    String? reason,
  }) async {
    final response = await dataProvider.declareAbsence(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
      direction: _directionToWire(direction),
      reason: (reason == null || reason.trim().isEmpty) ? null : reason.trim(),
    );

    if (!response.isSuccess) return _toFailure<Absence>(response);

    final absence = _parse(response.data, studentId);
    if (absence == null) return const Failure<Absence>(ErrorCode.internalError);
    return Success<Absence>(absence);
  }

  Future<Result<List<Absence>>> fetchAbsences({required String studentId}) async {
    final response = await dataProvider.fetchAbsences(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<Absence>>(response);

    final absences = response.dataList
        .whereType<Map<String, Object?>>()
        .map((raw) => _parse(raw, studentId))
        .whereType<Absence>()
        .toList(growable: false)
      ..sort((a, b) => a.fromDate.compareTo(b.fromDate));

    return Success<List<Absence>>(absences);
  }

  Future<Result<void>> cancelAbsence({
    required String studentId,
    required String absenceId,
  }) async {
    final response =
        await dataProvider.cancelAbsence(studentId: studentId, absenceId: absenceId);
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  /// `PICKUP` / `DROP`, not `MORNING` / `AFTERNOON`.
  ///
  /// An absence is subtracted from a trip's manifest, and a trip is keyed by the operational
  /// direction (docs/04-api/TRIPS_BOARDING_API.md § Absence, docs/03-database MOD-08). The
  /// parent-facing halves of the day are a *presentation* of that, applied by the screen —
  /// journey history and child detail translate the other way for the same reason.
  ///
  /// Null means both journeys, matching the documented `"direction": null` exactly.
  static String? _directionToWire(AbsenceDirection direction) => switch (direction) {
        AbsenceDirection.both => null,
        AbsenceDirection.morningOnly => 'PICKUP',
        AbsenceDirection.afternoonOnly => 'DROP',
      };

  static AbsenceDirection _directionFromWire(String? wire) => switch (wire) {
        'PICKUP' => AbsenceDirection.morningOnly,
        'DROP' => AbsenceDirection.afternoonOnly,
        _ => AbsenceDirection.both,
      };

  static Absence? _parse(Map<String, Object?> raw, String studentId) {
    final id = raw['id'] as String?;
    final fromDate = DateTime.tryParse(raw['fromDate'] as String? ?? '');
    final toDate = DateTime.tryParse(raw['toDate'] as String? ?? '');
    if (id == null || fromDate == null || toDate == null) return null;

    return Absence(
      id: id,
      studentId: (raw['studentId'] as String?) ?? studentId,
      fromDate: fromDate,
      toDate: toDate,
      direction: _directionFromWire(raw['direction'] as String?),
      reason: raw['reason'] as String?,
    );
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return const Failure(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
    );
  }
}
