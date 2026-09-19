import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/student_transport_models.dart';

/// The assigned-transport panel for one student (A-11), including its loading and error
/// conditions. Read-only: nothing on this panel writes.
class StudentTransportState extends Equatable {
  const StudentTransportState({this.isLoading = false, this.transport, this.error});

  final bool isLoading;

  /// Null until the first successful load.
  final StudentTransport? transport;

  final ErrorCode? error;

  @override
  List<Object?> get props => [isLoading, transport, error];
}
