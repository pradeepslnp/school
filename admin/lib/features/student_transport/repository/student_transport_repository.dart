import '../../../core/domain.dart';
import '../data_provider/student_transport_data_provider.dart';
import '../domain/student_transport_models.dart';

/// Turns student-transport transport into domain outcomes.
///
/// The bloc depends on this, never on [StudentTransportDataProvider] directly — matching
/// `RouteAssignmentRepository`, so a bloc test runs with a fake repository and no HTTP.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StudentTransportRepository {
  StudentTransportRepository({required this.dataProvider});

  final StudentTransportDataProvider dataProvider;

  Future<Result<StudentTransport>> getTransport({required String studentId}) async {
    final response = await dataProvider.getTransport(studentId: studentId);
    if (!response.isSuccess) {
      if (response.isTransportFailure) {
        return const Failure<StudentTransport>(ErrorCode.dependencyUnavailable);
      }
      return Failure<StudentTransport>(
        ErrorCode.fromWire(response.errorCode),
        messageKey: response.errorMessageKey,
        businessRule: response.errorBusinessRule,
      );
    }

    final legs = response.data['legs'];
    if (legs is! List) {
      // A 2xx we cannot read is a contract breach — matching StudentRepository.
      return const Failure<StudentTransport>(ErrorCode.internalError);
    }
    return Success<StudentTransport>(
      StudentTransport(
        legs: legs
            .whereType<Map<String, Object?>>()
            .map(_parseLeg)
            .whereType<TransportLeg>()
            .toList(growable: false),
      ),
    );
  }

  TransportLeg? _parseLeg(Map<String, Object?> data) {
    final direction = data['direction'];
    final routeCode = data['routeCode'];
    final routeName = data['routeName'];
    final stopName = data['stopName'];
    if (direction is! String ||
        routeCode is! String ||
        routeName is! String ||
        stopName is! String) {
      return null;
    }
    final crew = data['crew'];
    return TransportLeg(
      direction: direction,
      routeCode: routeCode,
      routeName: routeName,
      stopName: stopName,
      vehicle: _parseVehicle(data['vehicle']),
      crew: crew is List
          ? crew
                .whereType<Map<String, Object?>>()
                .map(_parseCrewMember)
                .whereType<TransportCrewMember>()
                .toList(growable: false)
          : const [],
    );
  }

  TransportVehicle? _parseVehicle(Object? data) {
    if (data is! Map<String, Object?>) return null;
    final registrationNo = data['registrationNo'];
    final displayName = data['displayName'];
    final status = data['status'];
    if (registrationNo is! String || displayName is! String || status is! String) return null;
    return TransportVehicle(
      registrationNo: registrationNo,
      displayName: displayName,
      status: status,
    );
  }

  TransportCrewMember? _parseCrewMember(Map<String, Object?> data) {
    final role = data['role'];
    final firstName = data['firstName'];
    final lastName = data['lastName'];
    if (role is! String || firstName is! String || lastName is! String) return null;
    return TransportCrewMember(role: role, firstName: firstName, lastName: lastName);
  }
}
