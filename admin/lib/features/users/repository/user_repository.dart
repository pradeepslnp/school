import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/user_data_provider.dart';
import '../domain/user_models.dart';

/// Turns administrative-user transport into domain outcomes.
///
/// The bloc depends on this, never on [UserDataProvider] directly — matching `StaffRepository`,
/// so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class UserRepository {
  UserRepository({required this.dataProvider});

  final UserDataProvider dataProvider;

  Future<Result<List<AdminUser>>> listUsers({required String organizationId}) async {
    final response = await dataProvider.listUsers(organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<List<AdminUser>>(response);

    final users = response.dataList
        .whereType<Map<String, Object?>>()
        .map(_parseUser)
        .whereType<AdminUser>()
        .toList(growable: false);
    return Success<List<AdminUser>>(users);
  }

  Future<Result<AdminUser>> createUser({
    required String organizationId,
    String? schoolId,
    required String email,
    String? phone,
    required String firstName,
    required String lastName,
    required String roleCode,
    String? initialPassword,
    required String deliveryMode,
  }) async {
    final response = await dataProvider.createUser(
      organizationId: organizationId,
      schoolId: schoolId,
      email: email.trim(),
      phone: phone?.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      roleCode: roleCode,
      initialPassword: initialPassword,
      deliveryMode: deliveryMode,
    );
    if (!response.isSuccess) return _toFailure<AdminUser>(response);

    final user = _parseUser(response.data);
    if (user == null) {
      // A 2xx we cannot read is a contract breach, not a validation problem — matching
      // StaffRepository's treatment of the same case.
      return const Failure<AdminUser>(ErrorCode.internalError);
    }
    return Success<AdminUser>(user);
  }

  /// Re-sends an invitation to a pending account (ADR-0012). Success carries no body.
  Future<Result<void>> resendInvitation({
    required String userId,
    required String organizationId,
  }) async {
    final response =
        await dataProvider.resendInvitation(userId: userId, organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  /// Sends a password-reset link to an active account (ADR-0012). Success carries no body.
  Future<Result<void>> sendResetLink({
    required String userId,
    required String organizationId,
  }) async {
    final response =
        await dataProvider.sendResetLink(userId: userId, organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<void>(response);
    return const Success<void>(null);
  }

  Future<Result<AdminUser>> updateUser({
    required String userId,
    required String organizationId,
    required String firstName,
    required String lastName,
    required String preferredLocale,
  }) async {
    final response = await dataProvider.updateUser(
      userId: userId,
      organizationId: organizationId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      preferredLocale: preferredLocale,
    );
    if (!response.isSuccess) return _toFailure<AdminUser>(response);

    final user = _parseUser(response.data);
    if (user == null) return const Failure<AdminUser>(ErrorCode.internalError);
    return Success<AdminUser>(user);
  }

  Future<Result<AdminUser>> deactivateUser({
    required String userId,
    required String organizationId,
  }) async {
    final response =
        await dataProvider.deactivateUser(userId: userId, organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<AdminUser>(response);

    final user = _parseUser(response.data);
    if (user == null) return const Failure<AdminUser>(ErrorCode.internalError);
    return Success<AdminUser>(user);
  }

  Future<Result<AdminUser>> reactivateUser({
    required String userId,
    required String organizationId,
  }) async {
    final response =
        await dataProvider.reactivateUser(userId: userId, organizationId: organizationId);
    if (!response.isSuccess) return _toFailure<AdminUser>(response);

    final user = _parseUser(response.data);
    if (user == null) return const Failure<AdminUser>(ErrorCode.internalError);
    return Success<AdminUser>(user);
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

  AdminUser? _parseUser(Map<String, Object?> data) {
    final id = data['id'];
    final email = data['email'];
    final firstName = data['firstName'];
    final lastName = data['lastName'];
    final status = data['status'];
    final roleCodes = data['roleCodes'];
    if (id is! String ||
        email is! String ||
        firstName is! String ||
        lastName is! String ||
        status is! String ||
        roleCodes is! List) {
      return null;
    }
    return AdminUser(
      id: id,
      email: email,
      phone: data['phone'] as String?,
      firstName: firstName,
      lastName: lastName,
      // Falls back to 'en' for a server that predates this field rather than failing the
      // whole parse over one optional-in-practice string — matching
      // `AuthenticatedUser.fromJson`'s own default for the same field.
      preferredLocale: data['preferredLocale'] as String? ?? 'en',
      status: status,
      roleCodes: roleCodes.whereType<String>().toList(growable: false),
      scopeLevel: data['scopeLevel'] as String?,
      scopeRefId: data['scopeRefId'] as String?,
    );
  }
}
