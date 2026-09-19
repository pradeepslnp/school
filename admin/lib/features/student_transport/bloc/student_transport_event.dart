import 'package:equatable/equatable.dart';

/// What happened to a student's assigned-transport panel (A-11).
sealed class StudentTransportEvent extends Equatable {
  const StudentTransportEvent();

  @override
  List<Object?> get props => const [];
}

/// The record was opened, or its pickup/drop assignment changed and the panel must re-read.
final class StudentTransportRequested extends StudentTransportEvent {
  const StudentTransportRequested({required this.studentId});

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}
