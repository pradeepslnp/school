import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for P-06, declaring and reviewing absences.
///
/// Contract: `POST /students/{id}/absences`, `GET /students/{id}/absences`,
/// `DELETE /absences/{id}` (docs/04-api/TRIPS_BOARDING_API.md § Absence), served by MOD-14.
class AbsenceDataProvider {
  AbsenceDataProvider({required this.client});

  final RestClient client;

  /// Declares an absence.
  ///
  /// No idempotency key, so [RestClient] does not retry this POST. That is the right trade
  /// here rather than an omission: a duplicate declaration is harmless — the same child
  /// excluded from the same manifest twice is the same outcome — so the server does not
  /// deduplicate, and a retry on a request that actually succeeded would simply create a
  /// second identical row for the parent to see.
  ///
  /// Refused with `422 ABSENCE_TRIP_ALREADY_STARTED` once the trip has left (BR-ABS-003).
  Future<ApiResponse> declareAbsence({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    required String? direction,
    required String? reason,
  }) {
    return client.post(
      '/students/$studentId/absences',
      body: {
        'fromDate': _dateOnly(fromDate),
        'toDate': _dateOnly(toDate),
        // Null means both journeys, matching the documented contract exactly rather than
        // inventing a third value the server would have to translate.
        'direction': direction,
        'reason': reason,
      },
    );
  }

  Future<ApiResponse> fetchAbsences({required String studentId}) =>
      client.get('/students/$studentId/absences');

  /// Cancels a declaration.
  ///
  /// `DELETE` is the client's intent; server-side the row is marked cancelled and kept, because
  /// a manifest may already have been built from it (BR-ABS-004).
  Future<ApiResponse> cancelAbsence({
    required String studentId,
    required String absenceId,
  }) =>
      client.delete('/absences/$absenceId');

  /// `YYYY-MM-DD` — a calendar date, deliberately not an instant
  /// (docs/04-api/API_STANDARDS.md).
  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
