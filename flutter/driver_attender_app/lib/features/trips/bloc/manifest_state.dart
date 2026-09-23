import 'package:equatable/equatable.dart';

import '../../../core/domain.dart';
import '../domain/manifest_models.dart';

/// The manifest screen for one run.
class ManifestState extends Equatable {
  const ManifestState({
    this.children = const [],
    this.isLoading = false,
    this.error,
    this.errorMessageKey,
    this.loadedAt,
  });

  final List<ManifestChild> children;
  final bool isLoading;
  final ErrorCode? error;
  final String? errorMessageKey;
  final DateTime? loadedAt;

  bool get hasLoaded => loadedAt != null;

  int get boardedCount =>
      children.where((child) => child.status == ManifestEntryStatus.boarded).length;

  int get expectedCount => children.length;

  /// Children who got on and have not got off. The number that matters at the end of a run: a
  /// non-zero count when the bus is empty is BR-SAFE-001's unaccounted child.
  int get stillAboardCount => boardedCount;

  ManifestState copyWith({
    List<ManifestChild>? children,
    bool? isLoading,
    ErrorCode? error,
    String? errorMessageKey,
    bool clearError = false,
    DateTime? loadedAt,
  }) {
    return ManifestState(
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      errorMessageKey: clearError ? null : (errorMessageKey ?? this.errorMessageKey),
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }

  @override
  List<Object?> get props => [children, isLoading, error, errorMessageKey, loadedAt];
}
