import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/audit_models.dart';
import '../repository/audit_repository.dart';
import 'audit_list_event.dart';
import 'audit_list_state.dart';

/// Loads the audit trail (A-54) or the override register (A-55).
///
/// Depends on a repository only, never a data provider — matching `UserListBloc`, so this is
/// tested with no HTTP and no fake server.
class AuditListBloc extends Bloc<AuditListEvent, AuditListState> {
  AuditListBloc({required AuditRepository repository})
      : _repository = repository,
        super(const AuditListState()) {
    on<AuditRequested>(_onRequested);
  }

  final AuditRepository _repository;

  Future<void> _onRequested(AuditRequested event, Emitter<AuditListState> emit) async {
    emit(state.copyWith(
      isLoading: true,
      overridesOnly: event.overridesOnly,
      clearError: true,
    ));

    final result = event.overridesOnly
        ? await _repository.listOverrides()
        : await _repository.listRecords();

    switch (result) {
      case Success<List<AuditRecord>>(:final value):
        emit(state.copyWith(isLoading: false, clearError: true, records: value));
      case Failure(:final code, :final messageKey):
        emit(state.copyWith(isLoading: false, error: code, errorMessageKey: messageKey));
    }
  }
}
