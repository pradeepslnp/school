import 'package:equatable/equatable.dart';

/// What the operator did on the audit trail (A-54/A-55).
sealed class AuditListEvent extends Equatable {
  const AuditListEvent();

  @override
  List<Object?> get props => const [];
}

/// Load the trail. [overridesOnly] switches between the full trail (A-54) and the override
/// register (A-55).
final class AuditRequested extends AuditListEvent {
  const AuditRequested({this.overridesOnly = false});

  final bool overridesOnly;

  @override
  List<Object?> get props => [overridesOnly];
}
