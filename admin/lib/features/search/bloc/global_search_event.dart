import 'package:equatable/equatable.dart';

/// What the operator did with global search (SRC-001).
sealed class GlobalSearchEvent extends Equatable {
  const GlobalSearchEvent();

  @override
  List<Object?> get props => const [];
}

/// The query text settled after a typing pause.
final class GlobalSearchQueryChanged extends GlobalSearchEvent {
  const GlobalSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The operator cleared the query.
final class GlobalSearchCleared extends GlobalSearchEvent {
  const GlobalSearchCleared();
}
