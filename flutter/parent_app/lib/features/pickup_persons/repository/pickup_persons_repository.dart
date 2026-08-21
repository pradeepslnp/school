import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/pickup_persons_data_provider.dart';
import 'models/pickup_person.dart';

/// Turns pickup-person transport into domain meaning.
///
/// The BLoC depends on this, never on [PickupPersonsDataProvider]
/// (ENGINEERING_PRINCIPLES.md §4).
class PickupPersonsRepository {
  PickupPersonsRepository({required this.dataProvider});

  final PickupPersonsDataProvider dataProvider;

  Future<Result<List<PickupPerson>>> fetchPickupPersons({
    required String studentId,
  }) async {
    final response = await dataProvider.fetchPickupPersons(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<PickupPerson>>(response);

    final people = response.dataList
        .whereType<Map<String, Object?>>()
        .map((raw) => _parse(raw, studentId))
        .whereType<PickupPerson>()
        .toList(growable: false)
      ..sort((a, b) => a.validUntil.compareTo(b.validUntil));

    return Success<List<PickupPerson>>(people);
  }

  Future<Result<PickupPerson>> addPickupPerson({
    required String studentId,
    required String fullName,
    required String phone,
    String? relationshipNote,
    required DateTime validFrom,
    required DateTime validUntil,
  }) async {
    final response = await dataProvider.addPickupPerson(
      studentId: studentId,
      fullName: fullName,
      phone: phone,
      relationshipNote: relationshipNote,
      validFrom: validFrom,
      validUntil: validUntil,
    );
    if (!response.isSuccess) return _toFailure<PickupPerson>(response);

    final person = _parse(response.data, studentId);
    if (person == null) return const Failure<PickupPerson>(ErrorCode.internalError);
    return Success<PickupPerson>(person);
  }

  Future<Result<void>> revokePickupPerson({
    required String studentId,
    required String pickupPersonId,
  }) async {
    final response = await dataProvider.revokePickupPerson(
      studentId: studentId,
      pickupPersonId: pickupPersonId,
    );
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  static PickupPerson? _parse(Map<String, Object?> raw, String studentId) {
    final id = raw['id'] as String?;
    final fullName = raw['fullName'] as String?;
    final phone = raw['phone'] as String?;
    final validFrom = _utc(raw['validFrom']);
    final validUntil = _utc(raw['validUntil']);
    if (id == null || fullName == null || phone == null || validFrom == null || validUntil == null) {
      return null;
    }

    return PickupPerson(
      id: id,
      studentId: studentId,
      fullName: fullName,
      phone: phone,
      relationshipNote: raw['relationshipNote'] as String?,
      validFrom: validFrom,
      validUntil: validUntil,
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

  static DateTime? _utc(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
