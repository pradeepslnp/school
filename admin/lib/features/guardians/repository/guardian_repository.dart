import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/guardian_data_provider.dart';
import '../domain/guardian_models.dart';

/// Turns guardian transport into domain outcomes.
///
/// The bloc depends on this, never on [GuardianDataProvider] directly — matching
/// `UserRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class GuardianRepository {
  GuardianRepository({required this.dataProvider});

  final GuardianDataProvider dataProvider;

  Future<Result<List<StudentGuardian>>> listGuardians({required String studentId}) async {
    final response = await dataProvider.listGuardians(studentId: studentId);
    if (!response.isSuccess) return _toFailure<List<StudentGuardian>>(response);

    final guardians = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseGuardian)
        .whereType<StudentGuardian>()
        .toList(growable: false);
    return Success<List<StudentGuardian>>(guardians);
  }

  Future<Result<StudentGuardian>> addGuardian({
    required String studentId,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String relationshipType,
    required bool canView,
    required bool canReceiveNotifications,
    required bool canAuthoriseHandover,
    required bool canDeclareAbsence,
    required bool isPrimary,
  }) async {
    final response = await dataProvider.addGuardian(
      studentId: studentId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      email: email?.trim(),
      relationshipType: relationshipType,
      canView: canView,
      canReceiveNotifications: canReceiveNotifications,
      canAuthoriseHandover: canAuthoriseHandover,
      canDeclareAbsence: canDeclareAbsence,
      isPrimary: isPrimary,
    );
    if (!response.isSuccess) return _toFailure<StudentGuardian>(response);

    final guardian = _parseGuardian(response.data);
    if (guardian == null) {
      // A 2xx we cannot read is a contract breach, not a validation problem — matching
      // UserRepository's treatment of the same case.
      return const Failure<StudentGuardian>(ErrorCode.internalError);
    }
    return Success<StudentGuardian>(guardian);
  }

  /// Nothing is read back: the response is the guardian record alone, while the panel shows each
  /// guardian with the rights on this child's link — so the caller re-lists instead.
  Future<Result<void>> updateGuardian({
    required String guardianId,
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
  }) async {
    final response = await dataProvider.updateGuardian(
      guardianId: guardianId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      email: email?.trim(),
    );
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  StudentGuardian? _parseGuardian(Map<String, Object?> data) {
    final linkId = data['linkId'];
    final guardianId = data['guardianId'];
    final firstName = data['firstName'];
    final lastName = data['lastName'];
    final phone = data['phone'];
    final relationshipType = data['relationshipType'];
    if (linkId is! String ||
        guardianId is! String ||
        firstName is! String ||
        lastName is! String ||
        phone is! String ||
        relationshipType is! String) {
      return null;
    }
    return StudentGuardian(
      linkId: linkId,
      guardianId: guardianId,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: data['email'] as String?,
      relationshipType: relationshipType,
      // Booleans default defensively: a record missing a right is treated as not holding it,
      // never as holding it — the safe direction for an authorisation flag.
      canView: data['canView'] as bool? ?? false,
      canReceiveNotifications: data['canReceiveNotifications'] as bool? ?? false,
      canAuthoriseHandover: data['canAuthoriseHandover'] as bool? ?? false,
      canDeclareAbsence: data['canDeclareAbsence'] as bool? ?? false,
      isPrimary: data['isPrimary'] as bool? ?? false,
      hasLogin: data['hasLogin'] as bool? ?? false,
    );
  }
}
