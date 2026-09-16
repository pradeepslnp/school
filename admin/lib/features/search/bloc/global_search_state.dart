import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/search_models.dart';

/// Where a search stands.
enum GlobalSearchStatus {
  /// Nothing typed.
  idle,

  /// Something typed, but shorter than a search the server accepts.
  tooShort,

  /// A search is in flight. Previous results stay visible under a progress bar rather than
  /// blanking on every keystroke.
  loading,

  /// Results for [GlobalSearchState.query] are in.
  ready,

  /// The search could not be answered.
  failed,
}

/// Global search (SRC-001), including its loading and error conditions.
///
/// One state class rather than a family of them, matching `StaffListState`.
class GlobalSearchState extends Equatable {
  const GlobalSearchState({
    this.query = '',
    this.status = GlobalSearchStatus.idle,
    this.results,
    this.error,
  });

  final String query;
  final GlobalSearchStatus status;
  final SearchResults? results;
  final ErrorCode? error;

  GlobalSearchState copyWith({
    String? query,
    GlobalSearchStatus? status,
    SearchResults? results,
    bool clearResults = false,
    ErrorCode? error,
    bool clearError = false,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: clearResults ? null : (results ?? this.results),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [query, status, results, error];
}
