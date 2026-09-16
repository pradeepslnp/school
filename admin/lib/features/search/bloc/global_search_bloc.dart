import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../domain/search_models.dart';
import '../repository/search_repository.dart';
import 'global_search_event.dart';
import 'global_search_state.dart';

/// Global search (SRC-001): turns what the operator typed into a search, and keeps only the answer
/// to what they typed most recently.
///
/// Depends on a repository only, matching every other bloc in this console. What a search may
/// return, and across how many organizations, is entirely the server's decision (ADR-0017,
/// ADR-0018); nothing here filters results.
class GlobalSearchBloc extends Bloc<GlobalSearchEvent, GlobalSearchState> {
  GlobalSearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const GlobalSearchState()) {
    on<GlobalSearchQueryChanged>(_onQueryChanged);
    on<GlobalSearchCleared>(_onCleared);
  }

  /// The server refuses anything shorter (BR-IAM-012, `SearchQuery.MIN_LENGTH`). Not sending it
  /// saves a round trip; it is not the control.
  static const int minQueryLength = 3;

  final SearchRepository _repository;

  Future<void> _onQueryChanged(
    GlobalSearchQueryChanged event,
    Emitter<GlobalSearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(state.copyWith(
        query: '',
        status: GlobalSearchStatus.idle,
        clearResults: true,
        clearError: true,
      ));
      return;
    }
    if (query.length < minQueryLength) {
      emit(state.copyWith(
        query: query,
        status: GlobalSearchStatus.tooShort,
        clearResults: true,
        clearError: true,
      ));
      return;
    }

    emit(state.copyWith(query: query, status: GlobalSearchStatus.loading, clearError: true));

    final result = await _repository.search(query: query);

    // Searches overlap while the operator types. An older, slower answer must never replace the
    // answer to what is in the field now.
    if (state.query != query) return;

    switch (result) {
      case Success<SearchResults>(:final value):
        emit(state.copyWith(status: GlobalSearchStatus.ready, results: value, clearError: true));
      case Failure(:final code):
        emit(state.copyWith(status: GlobalSearchStatus.failed, error: code, clearResults: true));
    }
  }

  void _onCleared(GlobalSearchCleared event, Emitter<GlobalSearchState> emit) {
    emit(state.copyWith(
      query: '',
      status: GlobalSearchStatus.idle,
      clearResults: true,
      clearError: true,
    ));
  }
}
